# NOTICE: GPLv3 企业内部自用。仅内部分发，不自商用，不对外开源。
# OpenProject 12.5.8 plugin openproject-internal_ext. See /NOTICE.

require 'csv'

module Iext
  module Export
    class Csv
      def self.bom_csv(headers, rows)
        body = CSV.generate do |csv|
          csv << headers
          rows.each { |r| csv << r }
        end
        "\uFEFF" + body
      end
    end
  end
end
