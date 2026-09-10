# NOTICE: GPLv3 企业内部自用。仅内部分发，不自商用，不对外开源。
# OpenProject 12.5.8 plugin openproject-internal_ext. See /NOTICE.

class CreateIextAuditLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :iext_audit_logs do |t|
      t.integer :actor_id
      t.string :action, null: false
      t.string :auditable_type
      t.integer :auditable_id
      t.integer :project_id
      t.jsonb :payload, default: {}
      t.string :ip
      t.timestamps null: false
    end
    add_index :iext_audit_logs, %i[auditable_type auditable_id]
    add_index :iext_audit_logs, :actor_id
    add_index :iext_audit_logs, :created_at
  end
end
