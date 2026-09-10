#!/bin/bash
# 确认官方 costs / reporting / budgets 引擎已加载（OpenProject 12.x）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

docker compose exec web bundle exec rails runner '
engines = Rails::Engine.subclasses.map(&:name)
need = %w[Costs::Engine OpenProject::Reporting::Engine Budgets::Engine]
missing = need - engines
puts "engines=#{engines.grep(/Cost|Report|Budget|Time/).join(",")}"
abort("MISSING engines: #{missing.join(",")}") unless missing.empty?
specs = Gem.loaded_specs.keys.grep(/cost|reporting|budget/)
puts "gems=#{specs.sort.join(",")}"
perms = OpenProject::AccessControl.permissions.map(&:name)
%i[log_time view_time_entries log_costs view_cost_entries].each do |p|
  abort("MISSING permission #{p}") unless perms.include?(p)
end
puts "disabled_modules=#{ENV["OPENPROJECT_DISABLED__MODULES"].inspect}"
puts "edition=#{ENV["OPENPROJECT_EDITION"]}"
puts "OK native Cost + 工时 permissions present"
'
