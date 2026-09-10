module Iext
  class ProgressBaseline < ApplicationRecord
    self.table_name = 'iext_progress_baselines'
    belongs_to :project
    belongs_to :user, optional: true
    validates :project, :version, presence: true
  end
end
