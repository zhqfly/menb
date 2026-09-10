# NOTICE: GPLv3 企业内部自用。仅内部分发，不自商用，不对外开源。
# OpenProject 12.5.8 plugin openproject-internal_ext. See /NOTICE.

module Iext
  class EvmController < BaseController
    before_action :find_project
    before_action :require_enterprise_module!
    before_action { deny_unless!(@project && (iext_admin? || iext_manager?(@project) || User.current.allowed_to?(:view_iext_evm, @project) || User.current.allowed_to?(:view_own_time_entries, @project))) }

    def show
      if iext_member_only?(@project)
        @own_hours = TimeEntry.where(project_id: @project.id, user_id: User.current.id).sum(:hours)
        @metrics = nil
      else
        @metrics = Iext::Evm::Calculator.new(@project).compute
        @over_budget = @metrics[:ac].to_f > @metrics[:bac].to_f || (@metrics[:cpi].to_f.positive? && @metrics[:cpi] < 1)
        @snapshots = Iext::EvmSnapshot.where(project_id: @project.id).order(as_of: :desc).limit(20)
        @baselines = Iext::BudgetBaseline.where(project_id: @project.id).order(created_at: :desc).limit(20)
      end
    end

    def snapshot
      deny_unless!(iext_manager?(@project))
      metrics = Iext::Evm::Calculator.new(@project).compute
      snap = Iext::EvmSnapshot.create!(metrics.merge(project: @project, user: User.current, as_of: Date.current))
      version = "B#{Time.current.strftime('%Y%m%d%H%M')}"
      Iext::BudgetBaseline.create!(
        project: @project,
        user: User.current,
        version: version,
        snapshot: metrics,
        notes: '预算/挣值基线'
      )
      Iext::Audit.log!(action: 'evm.snapshot', actor: User.current, auditable: snap, project: @project, payload: metrics.except(:breakdown), ip: request.remote_ip)
      flash[:notice] = I18n.t('iext.notice.snapshot_saved')
      redirect_to iext_evm_path(project_id: @project.id)
    end

    def export
      deny_unless!(iext_manager?(@project) || iext_admin?)
      metrics = Iext::Evm::Calculator.new(@project).compute
      csv = Iext::Export::Csv.bom_csv(
        %w[指标 数值],
        metrics.except(:breakdown).map { |k, v| [k.to_s.upcase, v] }
      )
      send_data csv, filename: "evm-#{@project.id}-#{Date.current}.csv", type: 'text/csv; charset=utf-8'
    end

    private

    def find_project
      @project = Project.find(params[:project_id])
    end
  end
end
