# NOTICE: GPLv3 企业内部自用。仅内部分发，不自商用，不对外开源。
# OpenProject 12.5.8 plugin openproject-internal_ext. See /NOTICE.

class CreateIextGanttTables < ActiveRecord::Migration[7.0]
  def change
    create_table :iext_process_templates do |t|
      t.string :name, null: false
      t.jsonb :stages, default: []
      t.boolean :active, default: true, null: false
      t.timestamps null: false
    end

    create_table :iext_progress_baselines do |t|
      t.integer :project_id, null: false
      t.integer :user_id
      t.string :version, null: false
      t.jsonb :snapshot, default: {}
      t.timestamps null: false
    end
    add_index :iext_progress_baselines, %i[project_id version], unique: true
  end
end
