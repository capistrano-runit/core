Capistrano::Configuration.instance(true).load do
  _cset :runit_resque_service_name, "resque"
  _cset :runit_resque_template, File.expand_path(File.join(File.dirname(__FILE__), "../templates/run-resque.erb"))
  _cset :runit_resque_command, defer { "#{rake} environment resque:work" }
  _cset :runit_resque_queue, "*"

  namespace :runit do
    namespace :resque do
      desc "Setup resque runit-service"
      task :setup, :roles => :app do
        run "[ -d #{runit_dir}/available/#{runit_resque_service_name} ] || mkdir -p #{runit_dir}/available/#{runit_resque_service_name}"
        template = File.read(runit_resque_template)
        erb_template = ERB.new(template)
        servers = find_servers_for_task(current_task)
        servers.each do |server|
          put erb_template.result(binding), "#{runit_dir}/available/#{runit_resque_service_name}/run", :mode => 0755, :hosts => server.host
        end
        find_and_execute_task "runit:resque:enable"
      end

      desc "Enable resque runit-service"
      task :enable, :roles => :app do
        run "cd #{runit_dir}/enabled && [ -h ./#{runit_resque_service_name} ] || ln -sf ../available/#{runit_resque_service_name} ."
      end

      desc "Disable resque runit-service"
      task :disable, :roles => :app do
        run "[ ! -h #{runit_dir}/enabled/#{runit_resque_service_name} ] || sv stop #{runit_dir}/enabled/#{runit_resque_service_name}/ && rm -f #{runit_dir}/enabled/#{runit_resque_service_name}"
      end

      desc "Restart resque runit-service"
      task :restart, :roles => :app do
        run "[ ! -h #{runit_dir}/enabled/#{runit_resque_service_name} ] || sv restart #{runit_dir}/enabled/#{runit_resque_service_name}/"
      end
    end
  end
end
