Dir.glob(File.expand_path("../runit/*.rake", __FILE__)) do |file|
  load file
end
