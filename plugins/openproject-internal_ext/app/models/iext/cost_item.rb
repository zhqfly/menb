# NOTICE: GPLv3 企业内部自用。仅内部分发，不自商用，不对外开源。
# OpenProject 12.5.8 plugin openproject-internal_ext. See /NOTICE.

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
