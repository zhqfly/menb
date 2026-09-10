# NOTICE: GPLv3 企业内部自用。仅内部分发，不自商用，不对外开源。
# OpenProject 12.5.8 plugin openproject-internal_ext. See /NOTICE.

module Iext
  class ShiftRule < ApplicationRecord
    self.table_name = 'iext_shift_rules'
    belongs_to :user
    validates :user, :weekday, :capacity_hours, presence: true
    validates :weekday, inclusion: { in: 0..6 }
  end
end
