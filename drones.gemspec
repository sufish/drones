Gem::Specification.new do |s|
  s.name        = 'drones'
  s.version     = '0.0.1'
  s.date        = '2013-07-11'
  s.files = Dir['{lib}/**/*']
  s.summary     = 'drone for async messaging client'
  s.description = 'drones'
  s.authors     = ['Qiang Fu']
  s.email       = 'fuqiang@aishua.cn'
  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'bunny', '>= 0.9.0'
  s.add_runtime_dependency 'oj'
  s.add_development_dependency 'rspec'
end
