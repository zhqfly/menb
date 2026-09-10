# NOTICE: GPLv3 企业内部自用。仅内部分发，不自商用，不对外开源。
# OpenProject 12.5.8 plugin openproject-internal_ext. See /NOTICE.

module Iext
  class BaseController < ApplicationController
    include PaginationHelper if defined?(PaginationHelper)

    before_action :require_login
    layout 'base'
    helper_method :iext_admin?, :iext_manager?, :iext_member_only?, :iext_global_costs?

    private

    def iext_admin?
      Iext::Access.admin?
    end

    def iext_manager?(project = @project)
      Iext::Access.manager_of?(project)
    end

    def iext_member_only?(project = @project)
      !iext_admin? && !iext_manager?(project)
    end

    def iext_global_costs?
      Iext::Access.can_view_global_costs?
    end

    def deny_unless!(cond)
      unless cond
        flash[:error] = I18n.t('iext.notice.forbidden')
        redirect_to '/'
        false
      end
    end

    def find_project
      @project = Project.find(params[:project_id]) if params[:project_id]
    end

    def require_enterprise_module!
      return unless @project

      deny_unless!(@project.module_enabled?(:iext_enterprise) || iext_admin?)
    end
  end
end
