module Iext
  class ShiftRule < ApplicationRecord
    self.table_name = 'iext_shift_rules'
    belongs_to :user
    validates :user, :weekday, :capacity_hours, presence: true
    validates :weekday, inclusion: { in: 0..6 }
  end
end
