module Iext
  class CostItem < ApplicationRecord
    self.table_name = 'iext_cost_items'
    CATEGORIES = %w[material outsource travel misc].freeze
    belongs_to :project
    belongs_to :work_package, optional: true
    belongs_to :user, optional: true
    validates :project, :category, :amount, :occurred_on, :subject, presence: true
    validates :category, inclusion: { in: CATEGORIES }
    validates :amount, numericality: true
  end
end
