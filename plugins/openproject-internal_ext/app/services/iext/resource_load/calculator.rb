module Iext
  module ResourceLoad
    class Calculator
      DEFAULT_CAPACITY = 8.0

      def initialize(from:, to:, users: nil)
        @from = from.to_date
        @to = to.to_date
        @users = users || begin
          User.not_builtin.where(status: 1)
        rescue StandardError
          User.where(status: 1)
        end
      end

      def heatmap
        holidays = Iext::Holiday.where(occurred_on: @from..@to).group_by(&:occurred_on)
        hours_by = TimeEntry.where(spent_on: @from..@to, user_id: @users.select(:id))
                            .group(:user_id, :spent_on).sum(:hours)
        rows = []
        @users.find_each do |user|
          (@from..@to).each do |day|
            cap = capacity_for(user, day, holidays[day] || [])
            hours = hours_by[[user.id, day]].to_f
            ratio = cap.positive? ? (hours / cap) : (hours.positive? ? 99 : 0)
            rows << {
              user: user,
              day: day,
              hours: hours,
              capacity: cap,
              ratio: ratio,
              weekend: weekend?(day),
              holiday: (holidays[day] || []).any? { |h| h.user_id.nil? || h.user_id == user.id }
            }
          end
        end
        rows
      end

      def utilization_rows
        heatmap.group_by { |r| r[:user] }.map do |user, cells|
          work = cells.reject { |c| c[:weekend] && c[:hours].zero? }
          cap = work.sum { |c| c[:capacity] }
          hours = work.sum { |c| c[:hours] }
          {
            user: user,
            hours: hours,
            capacity: cap,
            utilization: cap.positive? ? (hours / cap * 100.0) : 0
          }
        end
      end

      def capacity_for(user, day, holiday_rows)
        personal = holiday_rows.select { |h| h.user_id == user.id || h.user_id.nil? }
        return 0.0 if personal.any? { |h| %w[holiday leave].include?(h.kind) }

        rule = Iext::ShiftRule.find_by(user_id: user.id, weekday: day.wday, active: true)
        return rule.capacity_hours.to_f if rule
        return 0.0 if weekend?(day)

        DEFAULT_CAPACITY
      end

      def weekend?(day)
        day.saturday? || day.sunday?
      end
    end
  end
end
