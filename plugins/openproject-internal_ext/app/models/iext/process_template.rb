module Iext
  class ProcessTemplate < ApplicationRecord
    self.table_name = 'iext_process_templates'
    validates :name, presence: true
  end
end
