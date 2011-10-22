Capistrano::Configuration.instance(true).load do
  _cset :runit_delayed_job_service_name, "delayed_job"
  _cset :runit_delayed_job_template, File.expand_path(File.join(File.dirname(__FILE__), "../templates/run-delayed_job.erb"))
  _cset :runit_delayed_job_environment, defer { { "RAILS_ENV" => fetch(:rails_env) } }
  _cset :runit_delayed_job_command, "./script/delayed_job"

  namespace :runit do
    namespace :delayed_job do
      desc "Setup delayed_job runit-service"
      task :setup, :roles => :app do
        run "[ -d #{runit_dir}/available/#{runit_delayed_job_service_name} ] || mkdir -p #{runit_dir}/available/#{runit_delayed_job_service_name}"
        template = File.read(runit_delayed_job_template)
        erb_template = ERB.new(template)
        servers = find_servers_for_task(current_task)
        servers.each do |server|
          put erb_template.result(binding), "#{runit_dir}/available/#{runit_delayed_job_service_name}/run", :mode => 0755, :hosts => server.host
        end
        find_and_execute_task "runit:delayed_job:enable"
      end

      desc "Enable delayed_job runit-service"
      task :enable, :roles => :app do
        run "cd #{runit_dir}/enabled && [ -h ./#{runit_delayed_job_service_name} ] || ln -sf ../available/#{runit_delayed_job_service_name} ."
      end

      desc "Disable delayed_job runit-service"
      task :disable, :roles => :app do
        run "[ ! -h #{runit_dir}/enabled/#{runit_delayed_job_service_name} ] || sv stop #{runit_dir}/enabled/#{runit_delayed_job_service_name}/ && rm -f #{runit_dir}/enabled/#{runit_delayed_job_service_name}"
      end

      desc "Start delayed_job runit-service"
      task :start, :roles => :app do
        run "[ ! -h #{runit_dir}/enabled/#{runit_delayed_job_service_name} ] || sv start #{runit_dir}/enabled/#{runit_delayed_job_service_name}/"
      end

      desc "Stop delayed_job runit-service"
      task :stop, :roles => :app do
        run "[ ! -h #{runit_dir}/enabled/#{runit_delayed_job_service_name} ] || sv stop #{runit_dir}/enabled/#{runit_delayed_job_service_name}/"
      end

      desc "Restart delayed_job runit-service"
      task :restart, :roles => :app do
        run "[ ! -h #{runit_dir}/enabled/#{runit_delayed_job_service_name} ] || sv restart #{runit_dir}/enabled/#{runit_delayed_job_service_name}/"
      end
    end
  end
end
