# NOTICE: GPLv3 企业内部自用。仅内部分发，不自商用，不对外开源。
# OpenProject 12.5.8 plugin openproject-internal_ext. See /NOTICE.

module Iext
  class ReportsController < BaseController
    def index; end

    def progress
      projects = visible_projects
      rows = projects.map do |p|
        wps = p.work_packages
        n = wps.count
        done = n.zero? ? 0 : (wps.sum(:done_ratio).to_f / n)
        late = wps.where('due_date < ? AND done_ratio < 100', Date.current).count
        hours = TimeEntry.where(project_id: p.id).sum(:hours)
        hours = TimeEntry.where(project_id: p.id, user_id: User.current.id).sum(:hours) if !Iext::Access.can_view_global_costs?
        [p.name, n, done.round(1), late, hours]
      end
      send_or_html('progress', %w[项目 工作包数 平均完成% 延期数 工时], rows)
    end

    def labor
      scope = TimeEntry.where(spent_on: 90.days.ago.to_date..Date.current)
      unless Iext::Access.can_view_global_costs?
        scope = scope.where(user_id: User.current.id)
      else
        pids = Iext::Access.managed_projects.map(&:id)
        scope = scope.where(project_id: pids) unless iext_admin?
      end
      grouped = scope.group(:user_id, :project_id).sum(:hours)
      users = User.where(id: grouped.keys.map(&:first)).index_by(&:id)
      projects = Project.where(id: grouped.keys.map(&:last)).index_by(&:id)
      rows = grouped.map do |(uid, pid), hours|
        u = users[uid]
        dept = Array(u&.try(:groups)).map(&:name).join('/')
        [u&.name, dept, projects[pid]&.name, hours]
      end
      send_or_html('labor', %w[人员 部门 项目 工时], rows)
    end

    def utilization
      users = Iext::Access.resource_users
      calc = Iext::ResourceLoad::Calculator.new(from: 30.days.ago.to_date, to: Date.current, users: users)
      rows = calc.utilization_rows.map { |r| [r[:user].name, r[:hours], r[:capacity], r[:utilization].round(1)] }
      send_or_html('utilization', %w[人员 工时 容量 利用率%], rows)
    end

    private

    def visible_projects
      if iext_admin?
        Project.visible(User.current)
      elsif Iext::Access.managed_projects.any?
        Iext::Access.managed_projects
      else
        Project.visible(User.current).select { |p| User.current.allowed_to?(:view_work_packages, p) }
      end
    rescue StandardError
      []
    end

    def send_or_html(kind, headers, rows)
      if params[:format] == 'csv' || request.format.csv?
        csv = Iext::Export::Csv.bom_csv(headers, rows)
        send_data csv, filename: "#{kind}-#{Date.current}.csv", type: 'text/csv; charset=utf-8'
      else
        @kind = kind
        @headers = headers
        @rows = rows
        render :table
      end
    end
  end
end
