Dir.glob(File.expand_path("../tasks/*.rake", __FILE__)) do |file|
  load file
end
