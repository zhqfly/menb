# NOTICE: GPLv3 企业内部自用。仅内部分发，不自商用，不对外开源。
# OpenProject 12.5.8 plugin openproject-internal_ext. See /NOTICE.

module Iext
  class AuditLog < ApplicationRecord
    self.table_name = 'iext_audit_logs'
    belongs_to :actor, class_name: 'User', optional: true
    belongs_to :project, optional: true
    belongs_to :auditable, polymorphic: true, optional: true
  end
end
