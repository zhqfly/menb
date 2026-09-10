module Iext
  class BudgetBaseline < ApplicationRecord
    self.table_name = 'iext_budget_baselines'
    belongs_to :project
    belongs_to :user, optional: true
    validates :project, :version, presence: true
  end
end
