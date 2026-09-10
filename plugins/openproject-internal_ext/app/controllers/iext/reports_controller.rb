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
        [p.name, n, done.round(1), late]
      end
      send_or_html('progress', %w[项目 工作包数 平均完成% 延期数], rows)
    end

    def labor
      scope = TimeEntry.where(spent_on: 90.days.ago.to_date..Date.current)
      scope = scope.where(user_id: User.current.id) if !iext_admin? && !User.current.allowed_to_globally?(:view_time_entries)
      grouped = scope.group(:user_id, :project_id).sum(:hours)
      users = User.where(id: grouped.keys.map(&:first)).index_by(&:id)
      projects = Project.where(id: grouped.keys.map(&:last)).index_by(&:id)
      rows = grouped.map do |(uid, pid), hours|
        [users[uid]&.name, projects[pid]&.name, hours]
      end
      send_or_html('labor', %w[人员 项目 工时], rows)
    end

    def utilization
      calc = Iext::ResourceLoad::Calculator.new(from: 30.days.ago.to_date, to: Date.current)
      rows = calc.utilization_rows.map { |r| [r[:user].name, r[:hours], r[:capacity], r[:utilization].round(1)] }
      if !iext_admin? && !iext_manager?
        rows.select! { |r| r[0] == User.current.name }
      end
      send_or_html('utilization', %w[人员 工时 容量 利用率%], rows)
    end

    private

    def visible_projects
      Project.visible(User.current)
    rescue StandardError
      Project.all.select { |p| User.current.allowed_to?(:view_work_packages, p) }
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
