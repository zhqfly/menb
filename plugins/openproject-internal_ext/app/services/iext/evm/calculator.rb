# NOTICE: GPLv3 企业内部自用。仅内部分发，不自商用，不对外开源。
# OpenProject 12.5.8 plugin openproject-internal_ext. See /NOTICE.

module Iext
  module Evm
    class Calculator
      def initialize(project, as_of: Date.current)
        @project = project
        @as_of = as_of.to_date
      end

      def compute
        wps = @project.work_packages
        bac = bac_total(wps)
        pv = 0.0
        ev = 0.0
        wps.find_each do |wp|
          weight = wp_weight(wp, bac, wps)
          pv += weight * planned_pct(wp)
          ev += weight * earned_pct(wp)
        end
        ac = actual_cost
        spi = pv.positive? ? (ev.to_f / pv) : 0.0
        cpi = ac.positive? ? (ev.to_f / ac) : 0.0
        eac = cpi.positive? ? (bac.to_f / cpi) : bac
        {
          bac: bac.round(2),
          pv: pv.round(2),
          ac: ac.round(2),
          ev: ev.round(2),
          spi: spi.round(4),
          cpi: cpi.round(4),
          eac: eac.round(2),
          cv: (ev - ac).round(2),
          sv: (ev - pv).round(2),
          breakdown: {
            labor_ac: labor_ac,
            extra_ac: extra_ac,
            unit_ac: unit_ac,
            extra_by_category: extra_by_category
          }
        }
      end

      def actual_cost
        labor_ac + unit_ac + extra_ac
      end

      def labor_ac
        rel = TimeEntry.where(project_id: @project.id).where('spent_on <= ?', @as_of)
        if rel.column_names.include?('overridden_costs')
          rel.sum(Arel.sql('COALESCE(overridden_costs, costs, 0)'))
        elsif rel.column_names.include?('costs')
          rel.sum(:costs)
        else
          rel.sum(:hours).to_f * 0
        end.to_f
      end

      def unit_ac
        return 0.0 unless defined?(CostEntry)

        rel = CostEntry.where(project_id: @project.id)
        rel = rel.where('spent_on <= ?', @as_of) if rel.column_names.include?('spent_on')
        if rel.column_names.include?('overridden_costs')
          rel.sum(Arel.sql('COALESCE(overridden_costs, costs, 0)'))
        else
          rel.sum(:costs)
        end.to_f
      rescue StandardError
        0.0
      end

      def extra_ac
        Iext::CostItem.where(project_id: @project.id).where('occurred_on <= ?', @as_of).sum(:amount).to_f
      end

      def extra_by_category
        Iext::CostItem.where(project_id: @project.id).where('occurred_on <= ?', @as_of)
                       .group(:category).sum(:amount)
      end

      def bac_total(wps)
        native = 0.0
        if defined?(Budget)
          @project.budgets.find_each do |b|
            native += b.labor_budget_items.sum { |i| (i.hours.to_f * i.try(:hourly_rate).to_f) }
            native += b.material_budget_items.sum { |i| i.units.to_f * i.cost_type.try(:rate).to_f }
          rescue StandardError
            native += 0
          end
        end
        extra_plan = Iext::CostItem.where(project_id: @project.id).sum(:amount).to_f
        native = wps.sum { |wp| wp.estimated_hours.to_f } if native <= 0
        native + extra_plan
      end

      def wp_weight(wp, bac, wps)
        est = wp.estimated_hours.to_f
        total_est = wps.sum { |w| w.estimated_hours.to_f }
        return bac / [wps.count, 1].max if total_est <= 0

        bac * (est / total_est)
      end

      def planned_pct(wp)
        start_d = wp.start_date || wp.created_at.to_date
        due = wp.due_date || @as_of
        return 1.0 if @as_of >= due
        return 0.0 if @as_of <= start_d

        span = [(due - start_d).to_f, 1.0].max
        ((@as_of - start_d).to_f / span).clamp(0.0, 1.0)
      end

      def earned_pct(wp)
        (wp.done_ratio.to_f / 100.0).clamp(0.0, 1.0)
      end
    end
  end
end
