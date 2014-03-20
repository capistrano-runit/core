require "capistrano/runit"
Dir.glob(File.expand_path("../runit_sidekiq/*.rake", __FILE__)) do |file|
  load file
end
