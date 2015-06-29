Gem::Specification.new do |spec|
  spec.name        = 'capistrano-runit-core'
  spec.version     = '0.2.0'
  spec.summary     = 'Capistrano3 core recipe to manage runit services'
  spec.homepage    = 'http://capistrano-runit.github.io'
  spec.author      = ['Oleksandr Simonov', 'Anton Ageev']
  spec.email       = ['alex@simonov.me', 'antage@gmail.com']
  spec.license     = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'capistrano', '>= 3.1'
  spec.add_runtime_dependency 'sshkit', '>= 1.3'
  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
end
