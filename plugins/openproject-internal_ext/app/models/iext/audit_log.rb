module Iext
  class AuditLog < ApplicationRecord
    self.table_name = 'iext_audit_logs'
    belongs_to :actor, class_name: 'User', optional: true
    belongs_to :project, optional: true
    belongs_to :auditable, polymorphic: true, optional: true
  end
end
