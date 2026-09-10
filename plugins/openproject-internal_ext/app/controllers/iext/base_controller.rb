module Iext
  class BaseController < ApplicationController
    include PaginationHelper if defined?(PaginationHelper)

    before_action :require_login
    layout 'base'
    helper_method :iext_admin?, :iext_manager?, :iext_member_only?

    private

    def iext_admin?
      User.current.admin?
    end

    def iext_manager?(project = @project)
      return true if iext_admin?
      return false unless project

      User.current.allowed_to?(:edit_project, project) ||
        User.current.allowed_to?(:manage_iext_cost_items, project) ||
        User.current.allowed_to?(:edit_time_entries, project)
    end

    def iext_member_only?(project = @project)
      !iext_admin? && !iext_manager?(project)
    end

    def deny_unless!(cond)
      unless cond
        flash[:error] = I18n.t('iext.notice.forbidden')
        redirect_to '/'
      end
    end

    def find_project
      @project = Project.find(params[:project_id]) if params[:project_id]
    end
  end
end
