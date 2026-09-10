# NOTICE: GPLv3 企业内部自用。仅内部分发，不自商用，不对外开源。
# OpenProject 12.5.8 plugin openproject-internal_ext. See /NOTICE.

class CreateIextDelayTraces < ActiveRecord::Migration[7.0]
  def change
    create_table :iext_delay_traces do |t|
      t.integer :project_id, null: false
      t.integer :work_package_id
      t.integer :user_id
      t.integer :days_late, default: 0
      t.string :reason, null: false
      t.date :due_on
      t.timestamps null: false
    end
    add_index :iext_delay_traces, :project_id
  end
end
