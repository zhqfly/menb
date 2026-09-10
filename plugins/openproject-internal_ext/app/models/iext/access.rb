# NOTICE: GPLv3 企业内部自用。仅内部分发，不自商用，不对外开源。
# OpenProject 12.5.8 plugin openproject-internal_ext. See /NOTICE.

module Iext
  class Access
    def self.admin?(user = User.current)
      user&.admin?
    end

    def self.manager_of?(project, user = User.current)
      return false unless user && project
      return true if admin?(user)

      user.allowed_to?(:edit_project, project) ||
        user.allowed_to?(:manage_iext_cost_items, project) ||
        user.allowed_to?(:manage_iext_evm, project) ||
        user.allowed_to?(:manage_iext_gantt_flow, project)
    end

    def self.managed_projects(user = User.current)
      return Project.all.to_a if admin?(user)

      visible = Project.visible(user)
      visible.select { |p| manager_of?(p, user) }
    rescue StandardError
      []
    end

    def self.resource_users(user = User.current)
      return User.where(status: 1) if admin?(user)

      projects = managed_projects(user)
      if projects.any?
        ids = Member.where(project_id: projects.map(&:id)).distinct.pluck(:user_id)
        User.where(id: ids, status: 1)
      else
        User.where(id: user.id)
      end
    rescue StandardError
      User.where(id: user.id)
    end

    def self.can_view_global_costs?(user = User.current)
      admin?(user) || managed_projects(user).any?
    end
  end
end
