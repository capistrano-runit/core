require "capistrano/runit"
Dir.glob(File.expand_path("../runit_puma/*.rake", __FILE__)) do |file|
  load file
end
