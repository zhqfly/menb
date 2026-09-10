# NOTICE: GPLv3 企业内部自用。仅内部分发，不自商用，不对外开源。
# OpenProject 12.5.8 plugin openproject-internal_ext. See /NOTICE.

module Iext
  class Holiday < ApplicationRecord
    self.table_name = 'iext_holidays'
    belongs_to :user, optional: true
    KINDS = %w[holiday leave makeup shift].freeze
    validates :occurred_on, :name, :kind, presence: true
    validates :kind, inclusion: { in: KINDS }
  end
end
