Capistrano::Configuration.instance(true).load do
  _cset :runit_sidekiq_service_name, "sidekiq"
  _cset :runit_sidekiq_template, File.expand_path(File.join(File.dirname(__FILE__), "../templates/run-sidekiq.erb"))
  _cset :runit_sidekiq_environment, {}
  _cset :runit_sidekiq_command, "sidekiq"
  _cset :runit_sidekiq_queues, ["default"]
  _cset :runit_sidekiq_processes, 4

  namespace :runit do
    namespace :sidekiq do
      desc "Setup sidekiq runit-service"
      task :setup, :roles => :app do
        run "[ -d #{runit_dir}/available/#{runit_sidekiq_service_name} ] || mkdir -p #{runit_dir}/available/#{runit_sidekiq_service_name}"
        template = File.read(runit_sidekiq_template)
        erb_template = ERB.new(template)
        servers = find_servers_for_task(current_task)
        servers.each do |server|
          put erb_template.result(binding), "#{runit_dir}/available/#{runit_sidekiq_service_name}/run", :mode => 0755, :hosts => server.host
        end
        find_and_execute_task "runit:sidekiq:enable"
      end

      desc "Enable sidekiq runit-service"
      task :enable, :roles => :app do
        run "cd #{runit_dir}/enabled && [ -h ./#{runit_sidekiq_service_name} ] || ln -sf ../available/#{runit_sidekiq_service_name} ."
      end

      desc "Disable sidekiq runit-service"
      task :disable, :roles => :app do
        run "[ ! -h #{runit_dir}/enabled/#{runit_sidekiq_service_name} ] || sv stop #{runit_dir}/enabled/#{runit_sidekiq_service_name}/ && rm -f #{runit_dir}/enabled/#{runit_sidekiq_service_name}"
      end

      desc "Start sidekiq runit-service"
      task :start, :roles => :app do
        run "[ ! -h #{runit_dir}/enabled/#{runit_sidekiq_service_name} ] || sv start #{runit_dir}/enabled/#{runit_sidekiq_service_name}/"
      end

      desc "Stop sidekiq runit-service"
      task :stop, :roles => :app do
        run "[ ! -h #{runit_dir}/enabled/#{runit_sidekiq_service_name} ] || sv stop #{runit_dir}/enabled/#{runit_sidekiq_service_name}/"
      end

      desc "Restart sidekiq runit-service"
      task :restart, :roles => :app do
        run "[ ! -h #{runit_dir}/enabled/#{runit_sidekiq_service_name} ] || sv restart #{runit_dir}/enabled/#{runit_sidekiq_service_name}/"
      end
    end
  end
end
