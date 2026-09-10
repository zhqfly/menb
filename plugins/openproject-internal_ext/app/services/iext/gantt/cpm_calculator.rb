# NOTICE: GPLv3 企业内部自用。仅内部分发，不自商用，不对外开源。
# OpenProject 12.5.8 plugin openproject-internal_ext. See /NOTICE.

module Iext
  module Gantt
    class CpmCalculator
      Node = Struct.new(:wp, :es, :ef, :ls, :lf, :slack, :critical, keyword_init: true)

      def initialize(project)
        @project = project
      end

      def compute
        wps = @project.work_packages.to_a
        nodes = wps.to_h { |wp| [wp.id, Node.new(wp: wp, es: 0, ef: duration(wp), ls: 0, lf: 0, slack: 0, critical: false)] }
        preds = Hash.new { |h, k| h[k] = [] }
        succs = Hash.new { |h, k| h[k] = [] }
        Relation.where(from_id: wps.map(&:id)).or(Relation.where(to_id: wps.map(&:id))).find_each do |rel|
          next unless %w[follows precedes].include?(rel.relation_type)

          pred_id, succ_id = if rel.relation_type == 'follows'
                               [rel.to_id, rel.from_id]
                             else
                               [rel.from_id, rel.to_id]
                             end
          next unless nodes[pred_id] && nodes[succ_id]

          preds[succ_id] << pred_id
          succs[pred_id] << succ_id
        end

        topo = topological(nodes.keys, succs)
        topo.each do |id|
          n = nodes[id]
          es = preds[id].map { |p| nodes[p].ef }.max || 0
          n.es = es
          n.ef = es + duration(n.wp)
        end
        project_end = nodes.values.map(&:ef).max || 0
        topo.reverse_each do |id|
          n = nodes[id]
          lf = succs[id].map { |s| nodes[s].ls }.min || project_end
          n.lf = lf
          n.ls = lf - duration(n.wp)
          n.slack = n.ls - n.es
          n.critical = n.slack.abs < 0.01
        end
        nodes.values
      end

      def successor_shifts
        shifts = []
        compute.each do |node|
          Relation.where(from_id: node.wp.id, relation_type: 'precedes').find_each do |rel|
            succ = WorkPackage.find_by(id: rel.to_id)
            next unless succ

            lag = rel.try(:lag).to_i
            expected_start = (node.wp.due_date || node.wp.start_date)
            next unless expected_start

            expected_start = expected_start + lag + 1
            current = succ.start_date
            next if current.nil? || current >= expected_start

            shifts << { work_package: succ, from: current, to: expected_start, predecessor: node.wp }
          end
        end
        shifts
      end

      def apply_shifts!(user)
        successor_shifts.each do |s|
          wp = s[:work_package]
          delta = (s[:to] - s[:from]).to_i
          wp.start_date = s[:to]
          wp.due_date = wp.due_date + delta if wp.due_date
          wp.save!
          Iext::Audit.log!(action: 'gantt.auto_shift', actor: user, auditable: wp, payload: s.slice(:from, :to).transform_values(&:to_s))
        end
      end

      def duration(wp)
        return 1 unless wp.start_date && wp.due_date

        [(wp.due_date - wp.start_date).to_i + 1, 1].max
      end

      def topological(ids, succs)
        incoming = Hash.new(0)
        ids.each { |id| succs[id].each { |s| incoming[s] += 1 } }
        queue = ids.select { |id| incoming[id].zero? }
        order = []
        while (id = queue.shift)
          order << id
          succs[id].each do |s|
            incoming[s] -= 1
            queue << s if incoming[s].zero?
          end
        end
        order.concat(ids - order)
      end
    end
  end
end
