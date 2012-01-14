Capistrano::Configuration.instance(true).load do
  _cset :runit_thinking_sphinx_service_name, "sphinx"
  _cset :runit_thinking_sphinx_template, File.expand_path(File.join(File.dirname(__FILE__), "../templates/run-sphinx.erb"))
  _cset :runit_thinking_sphinx_environment, defer { fetch(:rails_env, "production") }
  _cset :runit_thinking_sphinx_searchd_command, "/usr/bin/searchd"

  namespace :runit do
    namespace :thinking_sphinx do
      desc "Setup Thinking Sphinx runit-service"
      task :setup, :roles => :db do
        run "[ -d #{runit_dir}/available/#{runit_thinking_sphinx_service_name} ] || mkdir -p #{runit_dir}/available/#{runit_thinking_sphinx_service_name}"
        template = File.read(runit_thinking_sphinx_template)
        erb_template = ERB.new(template)
        servers = find_servers_for_task(current_task)
        servers.each do |server|
          put erb_template.result(binding), "#{runit_dir}/available/#{runit_thinking_sphinx_service_name}/run", :mode => 0755, :hosts => server.host
        end
        find_and_execute_task "runit:thinking_sphinx:enable"
      end

      desc "Enable Thinking Sphinx runit-service"
      task :enable, :roles => :db do
        run "cd #{runit_dir}/enabled && [ -h ./#{runit_thinking_sphinx_service_name} ] || ln -sf ../available/#{runit_thinking_sphinx_service_name} ."
      end

      desc "Disable Thinking Sphinx runit-service"
      task :disable, :roles => :db do
        run "[ ! -h #{runit_dir}/enabled/#{runit_thinking_sphinx_service_name} ] || sv stop #{runit_dir}/enabled/#{runit_thinking_sphinx_service_name}/ && rm -f #{runit_dir}/enabled/#{runit_thinking_sphinx_service_name}"
      end

      desc "Start Thinking Sphinx runit-service"
      task :start, :roles => :db do
        run "[ ! -h #{runit_dir}/enabled/#{runit_thinking_sphinx_service_name} ] || sv start #{runit_dir}/enabled/#{runit_thinking_sphinx_service_name}/"
      end

      desc "Stop Thinking Sphinx runit-service"
      task :stop, :roles => :db do
        run "[ ! -h #{runit_dir}/enabled/#{runit_thinking_sphinx_service_name} ] || sv stop #{runit_dir}/enabled/#{runit_thinking_sphinx_service_name}/"
      end

      desc "Restart Thinking Sphinx runit-service"
      task :restart, :roles => :db do
        run "[ ! -h #{runit_dir}/enabled/#{runit_thinking_sphinx_service_name} ] || sv restart #{runit_dir}/enabled/#{runit_thinking_sphinx_service_name}/"
      end
    end
  end
end
