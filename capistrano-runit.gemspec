Gem::Specification.new do |s|
  s.name = "capistrano-runit"
  s.version = "1.1.3"
  s.summary = "Useful deployment recipes."
  s.homepage = "https://github.com/antage/capistrano-runit"
  s.author = "Anton Ageev"
  s.email = "antage@gmail.com"
  s.files = `git ls-files`.split
  s.add_dependency "capistrano", ">= 2.0.0"
end

# vim:ts=2 sw=2 ft=ruby
