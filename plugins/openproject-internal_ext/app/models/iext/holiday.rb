module Iext
  class Holiday < ApplicationRecord
    self.table_name = 'iext_holidays'
    belongs_to :user, optional: true
    KINDS = %w[holiday leave makeup shift].freeze
    validates :occurred_on, :name, :kind, presence: true
    validates :kind, inclusion: { in: KINDS }
  end
end
