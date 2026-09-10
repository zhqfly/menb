# NOTICE: GPLv3 企业内部自用。仅内部分发，不自商用，不对外开源。
# OpenProject 12.5.8 plugin openproject-internal_ext. See /NOTICE.

module Iext
  class EvmSnapshot < ApplicationRecord
    self.table_name = 'iext_evm_snapshots'
    belongs_to :project
    belongs_to :user, optional: true
    validates :project, :as_of, presence: true
  end
end
