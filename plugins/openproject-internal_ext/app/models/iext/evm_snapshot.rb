module Iext
  class EvmSnapshot < ApplicationRecord
    self.table_name = 'iext_evm_snapshots'
    belongs_to :project
    belongs_to :user, optional: true
    validates :project, :as_of, presence: true
  end
end
