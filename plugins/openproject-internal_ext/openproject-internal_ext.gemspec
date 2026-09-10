Gem::Specification.new do |s|
  s.name        = 'openproject-internal_ext'
  s.version     = '12.5.8.1'
  s.authors     = ['Internal']
  s.summary     = 'Internal OpenProject 12.5.8 enterprise plugins (resource/EVM/gantt/reports)'
  s.description = 'Plugin-only extensions. Does not replace native costs, time entries, budgets or reporting.'
  s.license     = 'GPL-3.0'
  s.files       = Dir['{app,config,db,lib}/**/*', 'README.md']
  s.require_paths = ['lib']
  s.metadata['rubygems_mfa_required'] = 'false'
end
