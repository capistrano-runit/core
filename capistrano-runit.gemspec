Gem::Specification.new do |s|
  s.name        = "capistrano-runit"
  s.version     = "2.0.0.rc1"
  s.summary     = "Capistrano recipes to manage runit services"
  s.homepage    = "https://github.com/antage/capistrano-runit"
  s.author      = ["Anton Ageev"]
  s.email       = ["antage@gmail.com"]
  s.license     = "MIT"

  s.files         = `git ls-files`.split($/)
  s.require_paths = ["lib"]

  s.add_runtime_dependency "capistrano", "~> 3.1"
  s.add_runtime_dependency "sshkit", "~> 1.3"
end
