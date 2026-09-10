module Iext
  module ResourceLoad
    class ConflictDetector
      def initialize(from:, to:)
        @from = from.to_date
        @to = to.to_date
      end

      def scan!
        calc = Calculator.new(from: @from, to: @to)
        created = 0
        calc.heatmap.group_by { |r| [r[:user], r[:day]] }.each do |(user, day), cells|
          cell = cells.first
          next if cell[:capacity] <= 0 && cell[:hours] <= 0

          kind = if cell[:hours] > cell[:capacity] && cell[:capacity].positive?
                   'overload'
                 elsif !cell[:weekend] && !cell[:holiday] && cell[:hours] < 2 && cell[:capacity].positive?
                   'idle'
                 end

          projects = TimeEntry.where(user_id: user.id, spent_on: day).distinct.count(:project_id)
          kind = 'conflict' if projects > 1 && cell[:hours] > cell[:capacity]

          next unless kind

          rec = Iext::ResourceAlert.find_or_initialize_by(user_id: user.id, spent_on: day, kind: kind)
          rec.hours = cell[:hours]
          rec.message = message_for(kind, user, day, cell, projects)
          rec.resolved_at = nil
          rec.save!
          created += 1 if rec.previous_changes.key?('id') || rec.saved_change_to_hours?
        end
        created
      end

      def message_for(kind, user, day, cell, projects)
        case kind
        when 'overload'
          "#{user.name} 在 #{day} 工时 #{cell[:hours]}h 超过容量 #{cell[:capacity]}h"
        when 'idle'
          "#{user.name} 在 #{day} 仅 #{cell[:hours]}h，低于空闲阈值"
        else
          "#{user.name} 在 #{day} 同时投入 #{projects} 个项目，工时 #{cell[:hours]}h 重叠"
        end
      end
    end
  end
end
