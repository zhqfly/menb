module Iext
  class GanttFlowController < BaseController
    before_action :find_project
    before_action { deny_unless!(@project && User.current.allowed_to?(:view_work_packages, @project)) }

    def show
      @nodes = Iext::Gantt::CpmCalculator.new(@project).compute
      @shifts = Iext::Gantt::CpmCalculator.new(@project).successor_shifts
      @baselines = Iext::ProgressBaseline.where(project_id: @project.id).order(created_at: :desc).limit(15)
      @templates = Iext::ProcessTemplate.where(active: true)
    end

    def apply_shift
      deny_unless!(iext_manager?(@project) || iext_admin?)
      Iext::Gantt::CpmCalculator.new(@project).apply_shifts!(User.current)
      flash[:notice] = I18n.t('iext.notice.shifted')
      redirect_to iext_gantt_flow_path(project_id: @project.id)
    end

    def save_baseline
      deny_unless!(iext_manager?(@project) || iext_admin?)
      snapshot = @project.work_packages.map do |wp|
        { id: wp.id, subject: wp.subject, start_date: wp.start_date, due_date: wp.due_date, done_ratio: wp.done_ratio }
      end
      version = "P#{Time.current.strftime('%Y%m%d%H%M')}"
      Iext::ProgressBaseline.create!(project: @project, user: User.current, version: version, snapshot: snapshot)
      Iext::Audit.log!(action: 'gantt.baseline', actor: User.current, project: @project, payload: { version: version }, ip: request.remote_ip)
      flash[:notice] = I18n.t('iext.notice.baseline_saved')
      redirect_to iext_gantt_flow_path(project_id: @project.id)
    end

    def apply_template
      deny_unless!(iext_manager?(@project) || iext_admin?)
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

    private

    def find_project
      @project = Project.find(params[:project_id])
    end
  end
end
