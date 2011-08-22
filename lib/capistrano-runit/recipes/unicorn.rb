Capistrano::Configuration.instance(true).load do
  _cset :runit_unicorn_service_name, "unicorn"
  _cset :runit_unicorn_template, File.expand_path(File.join(File.dirname(__FILE__), "../templates/run-unicorn.erb"))
  _cset :runit_unicorn_command, "unicorn"
  _cset :runit_unicorn_workers, 4
  _cset :runit_unicorn_listen, "127.0.0.1"
  _cset :runit_unicorn_port, 8080
  _cset :runit_unicorn_after_fork_code, ""

  namespace :runit do
    namespace :unicorn do
      desc "Setup Unicorn runit-service"
      task :setup, :roles => :app do
        run "[ -d #{runit_dir}/available/#{runit_unicorn_service_name} ] || mkdir -p #{runit_dir}/available/#{runit_unicorn_service_name}"
        template = File.read(runit_unicorn_template)
        erb_template = ERB.new(template)
        servers = find_servers_for_task(current_task)
        servers.each do |server|
          runit_unicorn_listen_current =
            if runit_unicorn_listen.is_a?(Hash)
              runit_unicorn_listen[server.host]
            else
              runit_unicorn_listen
            end
          runit_unicorn_port_current =
            if runit_unicorn_port.is_a?(Hash)
              runit_unicorn_port[server.host]
            else
              runit_unicorn_port
            end
          runit_unicorn_workers_current =
            if runit_unicorn_workers.is_a?(Hash)
              runit_unicorn_workers[server.host]
            else
              runit_unicorn_workers
            end
          put erb_template.result(binding), "#{runit_dir}/available/#{runit_unicorn_service_name}/run", :mode => 0755, :hosts => server.host
        end
        find_and_execute_task "runit:unicorn:enable"
      end

      desc "Enable Unicorn runit-service"
      task :enable, :roles => :app do
        run "cd #{runit_dir}/enabled && [ -h ./#{runit_unicorn_service_name} ] || ln -sf ../available/#{runit_unicorn_service_name} ."
      end

      desc "Enable Unicorn runit-service"
      task :disable, :roles => :app do
        run "[ ! -h #{runit_dir}/enabled/#{runit_unicorn_service_name} ] || sv stop #{runit_dir}/enabled/#{runit_unicorn_service_name}/ && rm -f #{runit_dir}/enabled/#{runit_unicorn_service_name}"
      end

      desc "Restart Unicorn runit-service"
      task :restart, :roles => :app do
        run "[ ! -h #{runit_dir}/enabled/#{runit_unicorn_service_name} ] || sv restart #{runit_dir}/enabled/#{runit_unicorn_service_name}/"
      end
    end
  end
end
