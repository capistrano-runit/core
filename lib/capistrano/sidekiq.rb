Dir.glob(File.expand_path("../sidekiq/*.rake", __FILE__)) do |file|
  load file
end
