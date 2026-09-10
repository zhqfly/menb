class GrantIextPermissionsAndSeeds < ActiveRecord::Migration[7.0]
  def up
    manager_perms = %i[
      view_iext_evm manage_iext_evm
      view_iext_cost_items manage_iext_cost_items
      view_iext_gantt_flow manage_iext_gantt_flow
      view_iext_reports
    ]
    member_perms = %i[view_iext_evm view_iext_cost_items view_iext_gantt_flow view_iext_reports]

    if defined?(Role)
      Role.find_each do |role|
        perms = role.permissions.map(&:to_sym)
        grant = if role.respond_to?(:builtin) && role.builtin.to_i == 0 && (perms.include?(:edit_project) || perms.include?(:manage_members) || perms.include?(:edit_time_entries))
                  manager_perms
                elsif perms.include?(:log_own_time) || perms.include?(:view_own_time_entries)
                  member_perms
                else
                  []
                end
        grant.each do |p|
          role.add_permission!(p) if role.respond_to?(:add_permission!) && !perms.include?(p)
        rescue StandardError
          nil
        end
      end
    end

    Iext::ProcessTemplate.find_or_create_by!(name: '企业标准全流程') do |t|
      t.stages = %w[立项 需求 开发 测试 交付 复盘]
    end

    holidays_2026 = [
      ['2026-01-01', '元旦', 'holiday'],
      ['2026-01-02', '元旦调休', 'leave'],
      ['2026-02-16', '春节', 'holiday'],
      ['2026-02-17', '春节', 'holiday'],
      ['2026-02-18', '春节', 'holiday'],
      ['2026-02-19', '春节', 'holiday'],
      ['2026-02-20', '春节', 'holiday'],
      ['2026-02-21', '春节', 'holiday'],
      ['2026-04-05', '清明', 'holiday'],
      ['2026-04-06', '清明调休', 'leave'],
      ['2026-05-01', '劳动节', 'holiday'],
      ['2026-05-02', '劳动节', 'holiday'],
      ['2026-05-03', '劳动节', 'holiday'],
      ['2026-06-19', '端午', 'holiday'],
      ['2026-09-25', '中秋', 'holiday'],
      ['2026-10-01', '国庆', 'holiday'],
      ['2026-10-02', '国庆', 'holiday'],
      ['2026-10-03', '国庆', 'holiday'],
      ['2026-10-04', '国庆', 'holiday'],
      ['2026-10-05', '国庆', 'holiday'],
      ['2026-10-06', '国庆', 'holiday'],
      ['2026-10-07', '国庆', 'holiday']
    ]
    holidays_2026.each do |d, name, kind|
      Iext::Holiday.find_or_create_by!(occurred_on: Date.parse(d), name: name) do |h|
        h.kind = kind
      end
    end
  rescue NameError
    # models not loaded yet during some rake tasks
  end

  def down
    # keep seeded calendar rows
  end
end
