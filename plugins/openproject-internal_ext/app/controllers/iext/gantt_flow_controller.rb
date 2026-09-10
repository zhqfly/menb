# NOTICE: GPLv3 企业内部自用。仅内部分发，不自商用，不对外开源。
# OpenProject 12.5.8 plugin openproject-internal_ext. See /NOTICE.

module Iext
  class GanttFlowController < BaseController
    before_action :find_project
    before_action :require_enterprise_module!
    before_action { deny_unless!(@project && User.current.allowed_to?(:view_work_packages, @project)) }

    def show
      @nodes = Iext::Gantt::CpmCalculator.new(@project).compute
      @shifts = Iext::Gantt::CpmCalculator.new(@project).successor_shifts
      @baselines = Iext::ProgressBaseline.where(project_id: @project.id).order(created_at: :desc).limit(15)
      @templates = Iext::ProcessTemplate.where(active: true)
      @delay_traces = Iext::DelayTrace.where(project_id: @project.id).order(created_at: :desc).limit(50)
      @compare = baseline_diff(@baselines.first)
      @late_wps = @project.work_packages.where('due_date < ? AND done_ratio < 100', Date.current)
    end

    def apply_shift
      deny_unless!(iext_manager?(@project))
      Iext::Gantt::CpmCalculator.new(@project).apply_shifts!(User.current)
      flash[:notice] = I18n.t('iext.notice.shifted')
      redirect_to iext_gantt_flow_path(project_id: @project.id)
    end

    def save_baseline
      deny_unless!(iext_manager?(@project))
      snapshot = @project.work_packages.map do |wp|
        { 'id' => wp.id, 'subject' => wp.subject, 'start_date' => wp.start_date, 'due_date' => wp.due_date, 'done_ratio' => wp.done_ratio }
      end
      version = "P#{Time.current.strftime('%Y%m%d%H%M')}"
      Iext::ProgressBaseline.create!(project: @project, user: User.current, version: version, snapshot: snapshot)
      Iext::Audit.log!(action: 'gantt.baseline', actor: User.current, project: @project, payload: { version: version }, ip: request.remote_ip)
      flash[:notice] = I18n.t('iext.notice.baseline_saved')
      redirect_to iext_gantt_flow_path(project_id: @project.id)
    end

    def apply_template
      deny_unless!(iext_manager?(@project))
      tpl = Iext::ProcessTemplate.find(params[:template_id])
      start = Date.current
      prev = nil
      Array(tpl.stages).each_with_index do |name, idx|
        wp = WorkPackage.new
        wp.project = @project
        wp.author = User.current
        wp.subject = name.to_s
        wp.start_date = start + (idx * 7)
        wp.due_date = start + (idx * 7) + 6
        wp.type = @project.types.detect { |t| t.respond_to?(:is_standard) && t.is_standard } || @project.types.first
        wp.status = (Status.respond_to?(:default) && Status.default) || Status.where(is_default: true).first || Status.first
        wp.priority = (IssuePriority.respond_to?(:default) && IssuePriority.default) || IssuePriority.first
        wp.save!
        if prev
          attrs = { from: prev, to: wp, relation_type: Relation::TYPE_PRECEDES }
          attrs[:lag] = 0 if Relation.column_names.include?('lag')
          Relation.create!(attrs)
        end
        prev = wp
      end
      Iext::Audit.log!(action: 'gantt.template', actor: User.current, project: @project, payload: { template: tpl.name }, ip: request.remote_ip)
      flash[:notice] = I18n.t('iext.notice.template_applied')
      redirect_to iext_gantt_flow_path(project_id: @project.id)
    rescue StandardError => e
      flash[:error] = e.message
      redirect_to iext_gantt_flow_path(project_id: @project.id)
    end

    def create_delay_trace
      deny_unless!(iext_manager?(@project) || User.current.allowed_to?(:log_own_time, @project))
      rec = Iext::DelayTrace.new(delay_params)
      rec.project = @project
      rec.user = User.current
      if rec.save
        Iext::Audit.log!(action: 'gantt.delay_trace', actor: User.current, auditable: rec, project: @project, payload: { reason: rec.reason }, ip: request.remote_ip)
        flash[:notice] = I18n.t('iext.notice.created')
      else
        flash[:error] = rec.errors.full_messages.join(', ')
      end
      redirect_to iext_gantt_flow_path(project_id: @project.id)
    end

    private

    def find_project
      @project = Project.find(params[:project_id])
    end

    def delay_params
      params.require(:iext_delay_trace).permit(:work_package_id, :days_late, :reason, :due_on)
    end

    def baseline_diff(baseline)
      return [] unless baseline

      rows = Array(baseline.snapshot)
      current = @project.work_packages.index_by(&:id)
      rows.filter_map do |row|
        h = row.stringify_keys
        wp = current[h['id'].to_i]
        next unless wp

        due0 = h['due_date'].present? ? Date.parse(h['due_date'].to_s) : nil
        start0 = h['start_date'].present? ? Date.parse(h['start_date'].to_s) : nil
        {
          subject: wp.subject,
          due_base: due0,
          due_now: wp.due_date,
          done_base: h['done_ratio'].to_i,
          done_now: wp.done_ratio.to_i,
          delayed: due0 && wp.due_date && wp.due_date > due0
        }
      rescue ArgumentError
        nil
      end
    end
  end
end
