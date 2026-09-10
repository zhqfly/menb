# NOTICE: GPLv3 企业内部自用。仅内部分发，不自商用，不对外开源。
# OpenProject 12.5.8 plugin openproject-internal_ext. See /NOTICE.

module Iext
  class DelayTrace < ApplicationRecord
    self.table_name = 'iext_delay_traces'
    belongs_to :project
    belongs_to :work_package, optional: true
    belongs_to :user, optional: true
    validates :project, :reason, presence: true
  end
end
