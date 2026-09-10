require 'open_project/plugins'

module OpenProject
  module InternalExt
    class Engine < ::Rails::Engine
      engine_name :openproject_internal_ext

      include OpenProject::Plugins::ActsAsOpEngine

      register 'openproject-internal_ext',
               author_url: 'https://www.openproject.org',
               bundled: false,
               settings: {
                 default: {
                   'capacity_hours' => '8',
                   'overload_ratio' => '1.0',
                   'idle_hours' => '2',
                   'currency' => 'CNY'
                 },
                 partial: 'iext/settings'
               } do
        menu :top_menu,
             :iext_resource_load,
             { controller: '/iext/resource_load', action: 'index' },
             caption: :label_iext_resource_load,
             after: :work_packages,
             if: Proc.new { User.current.logged? }

        menu :top_menu,
             :iext_reports,
             { controller: '/iext/reports', action: 'index' },
             caption: :label_iext_reports,
             after: :iext_resource_load,
             if: Proc.new { User.current.logged? }

        menu :project_menu,
             :iext_evm,
             { controller: '/iext/evm', action: 'show' },
             caption: :label_iext_evm,
             after: :costs,
             icon: 'icon2 icon-budget',
             if: ->(project) { project.module_enabled?(:costs) || project.module_enabled?(:budgets) }

        menu :project_menu,
             :iext_cost_items,
             { controller: '/iext/cost_items', action: 'index' },
             caption: :label_iext_cost_items,
             after: :iext_evm,
             icon: 'icon2 icon-cost-types'

        menu :project_menu,
             :iext_gantt_flow,
             { controller: '/iext/gantt_flow', action: 'show' },
             caption: :label_iext_gantt_flow,
             after: :work_packages,
             icon: 'icon2 icon-view-timeline'

        menu :admin_menu,
             :iext_admin,
             { controller: '/iext/holidays', action: 'index' },
             caption: :label_iext_admin,
             if: Proc.new { User.current.admin? },
             icon: 'icon2 icon-calendar'

        project_module :iext_enterprise do
          permission :view_iext_evm, { 'iext/evm': %i[show export] }
          permission :manage_iext_evm, { 'iext/evm': %i[show snapshot] }
          permission :view_iext_cost_items, { 'iext/cost_items': %i[index show] }
          permission :manage_iext_cost_items, {
            'iext/cost_items': %i[index show new create edit update destroy]
          }, require: :member
          permission :view_iext_gantt_flow, { 'iext/gantt_flow': %i[show] }
          permission :manage_iext_gantt_flow, {
            'iext/gantt_flow': %i[show apply_shift save_baseline apply_template]
          }, require: :member
          permission :view_iext_reports, { 'iext/reports': %i[index progress labor utilization] }
        end
      end

      config.to_prepare do
        ::Iext::Audit
      end
    end
  end
end
