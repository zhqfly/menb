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
