# NOTICE: GPLv3 企业内部自用。仅内部分发，不自商用，不对外开源。
# OpenProject 12.5.8 plugin openproject-internal_ext. See /NOTICE.

module Iext
  class ResourceAlert < ApplicationRecord
    self.table_name = 'iext_resource_alerts'
    belongs_to :user
    KINDS = %w[overload idle conflict].freeze
    validates :user, :spent_on, :kind, presence: true
    scope :open, -> { where(resolved_at: nil) }
  end
end
