module Iext
  class ResourceAlert < ApplicationRecord
    self.table_name = 'iext_resource_alerts'
    belongs_to :user
    KINDS = %w[overload idle conflict].freeze
    validates :user, :spent_on, :kind, presence: true
    scope :open, -> { where(resolved_at: nil) }
  end
end
