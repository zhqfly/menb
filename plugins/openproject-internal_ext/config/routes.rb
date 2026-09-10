OpenProject::Application.routes.draw do
  namespace :iext do
    get 'resource_load', to: 'resource_load#index'
    get 'resource_load/export', to: 'resource_load#export'
    post 'resource_load/scan', to: 'resource_load#scan'

    resources :holidays, except: %i[show]
    resources :shift_rules, except: %i[show]

    resources :cost_items, except: %i[show]
    get 'evm', to: 'evm#show'
    post 'evm/snapshot', to: 'evm#snapshot'
    get 'evm/export', to: 'evm#export'

    get 'gantt_flow', to: 'gantt_flow#show'
    post 'gantt_flow/apply_shift', to: 'gantt_flow#apply_shift'
    post 'gantt_flow/save_baseline', to: 'gantt_flow#save_baseline'
    post 'gantt_flow/apply_template', to: 'gantt_flow#apply_template'

    get 'reports', to: 'reports#index'
    get 'reports/progress', to: 'reports#progress'
    get 'reports/labor', to: 'reports#labor'
    get 'reports/utilization', to: 'reports#utilization'
  end
end
