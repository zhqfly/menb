module Iext
  class ResourceLoadController < BaseController
    def index
      @from = parse_date(params[:from], Date.current.beginning_of_week)
      @to = parse_date(params[:to], Date.current.end_of_week)
      @calc = Iext::ResourceLoad::Calculator.new(from: @from, to: @to)
      @cells = @calc.heatmap
      @grid = @cells.each_with_object({}) { |c, h| h[[c[:user].id, c[:day]]] = c }
      @users = @cells.map { |c| c[:user] }.uniq
      @days = (@from..@to).to_a
      @alerts = Iext::ResourceAlert.open.where(spent_on: @from..@to).includes(:user).order(spent_on: :desc)
      @utilization = @calc.utilization_rows
    end

    def scan
      deny_unless!(iext_admin? || User.current.allowed_to_globally?(:manage_user))
      from = parse_date(params[:from], Date.current.beginning_of_week)
      to = parse_date(params[:to], Date.current.end_of_week)
      n = Iext::ResourceLoad::ConflictDetector.new(from: from, to: to).scan!
      Iext::Audit.log!(action: 'resource.scan', actor: User.current, payload: { from: from, to: to, created: n }, ip: request.remote_ip)
      flash[:notice] = "#{I18n.t('iext.notice.alerts_scanned')} (#{n})"
      redirect_to iext_resource_load_path(from: from, to: to)
    end

    def export
      from = parse_date(params[:from], Date.current.beginning_of_week)
      to = parse_date(params[:to], Date.current.end_of_week)
      rows = Iext::ResourceLoad::Calculator.new(from: from, to: to).utilization_rows
      csv = Iext::Export::Csv.bom_csv(
        %w[用户 工时 容量 利用率%],
        rows.map { |r| [r[:user].name, r[:hours], r[:capacity], r[:utilization].round(1)] }
      )
      send_data csv, filename: "resource-utilization-#{from}-#{to}.csv", type: 'text/csv; charset=utf-8'
    end

    private

    def parse_date(value, default)
      value.present? ? Date.parse(value) : default
    rescue ArgumentError
      default
    end
  end
end
