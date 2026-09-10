# NOTICE: GPLv3 企业内部自用。仅内部分发，不自商用，不对外开源。
# OpenProject 12.5.8 plugin openproject-internal_ext. See /NOTICE.

module Iext
  class CostItemsController < BaseController
    before_action :find_optional_project
    before_action :require_enterprise_module!, if: -> { @project }
    before_action :authorize_view

    def index
      scope = Iext::CostItem.order(occurred_on: :desc)
      if @project
        scope = scope.where(project_id: @project.id)
        scope = scope.where(user_id: User.current.id) if iext_member_only?(@project)
      elsif iext_admin?
        scope
      elsif iext_global_costs?
        scope = scope.where(project_id: Iext::Access.managed_projects.map(&:id))
      else
        scope = scope.where(user_id: User.current.id)
      end
      @cost_items = scope.limit(500)
      @cost_item = Iext::CostItem.new(project: @project, occurred_on: Date.current, user: User.current)
    end

    def create
      item = Iext::CostItem.new(cost_params)
      item.user ||= User.current
      item.project ||= @project
      deny_unless!(iext_manager?(item.project))
      if item.save
        Iext::Audit.log!(action: 'cost_item.create', actor: User.current, auditable: item, project: item.project, ip: request.remote_ip)
        flash[:notice] = I18n.t('iext.notice.created')
      else
        flash[:error] = item.errors.full_messages.join(', ')
      end
      redirect_back fallback_location: iext_cost_items_path(project_id: item.project_id)
    end

    def destroy
      item = Iext::CostItem.find(params[:id])
      deny_unless!(iext_manager?(item.project))
      Iext::Audit.log!(action: 'cost_item.delete', actor: User.current, payload: { id: item.id, amount: item.amount }, project: item.project, ip: request.remote_ip)
      item.destroy
      flash[:notice] = I18n.t('iext.notice.deleted')
      redirect_back fallback_location: iext_cost_items_path(project_id: item.project_id)
    end

    private

    def find_optional_project
      @project = Project.find_by(id: params[:project_id]) if params[:project_id]
    end

    def authorize_view
      deny_unless!(User.current.logged?)
    end

    def cost_params
      params.require(:iext_cost_item).permit(:project_id, :work_package_id, :category, :amount, :occurred_on, :vendor, :subject, :notes)
    end
  end
end
