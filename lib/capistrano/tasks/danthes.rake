require 'erb'

namespace :load do
  task :defaults do
    set :runit_danthes_role, -> { :app }
    set :runit_danthes_default_hooks, -> { true }
    set :runit_danthes_run_template, File.expand_path('../../templates/run-danthes.erb', __FILE__)
    set :runit_danthes_threads_min, 0
    set :runit_danthes_threads_max, 16
    set :runit_danthes_rackup, -> { File.join(current_path, 'danthes.ru') }
    set :runit_danthes_state, -> { File.join(shared_path, 'tmp', 'pids', 'danthes.state') }
    set :runit_danthes_pid, -> { File.join(shared_path, 'tmp', 'pids', 'danthes.pid') }
    set :runit_danthes_bind, -> { 'tcp://127.0.0.1:9292' }
    set :runit_danthes_conf, -> { File.join(shared_path, 'danthes.rb') }
    set :runit_danthes_conf_in_repo, -> { false }
    set :runit_danthes_access_log, -> { File.join(shared_path, 'log', 'danthes_access.log') }
    set :runit_danthes_error_log, -> { File.join(shared_path, 'log', 'danthes_error.log') }
  end
end

namespace :deploy do
  before :starting, :runit_check_danthes_hooks do
    invoke 'runit:danthes:add_default_hooks' if fetch(:runit_danthes_default_hooks)
  end
end

namespace :runit do
  namespace :danthes do

    def path_to_danthes_service_dir
      "#{deploy_to}/runit/enabled/danthes/"
    end

    def template_danthes(from, to)
      [
        File.expand_path("../#{from}.rb.erb", __FILE__),
        File.expand_path("../#{from}.erb", __FILE__)
      ].each do |path|
        if File.file?(path)
          template = ERB.new(File.read(path))
          stream   = StringIO.new(template.result(binding))
          upload! stream, "#{to}"
          break
        end
      end
    end

    def collect_danthes_run_command
      array = []
      array << SSHKit.config.default_env.map { |k, v| "#{k.upcase}=\"#{v}\"" }.join('')
      array << "exec #{SSHKit.config.command_map[:bundle]} exec puma"
      danthes_conf_path = if fetch(:runit_danthes_conf_in_repo)
                         "#{release_path}/config/danthes.rb"
                       else
                         fetch(:runit_danthes_conf)
                       end
      array << "-C #{danthes_conf_path}"
      array.compact.join(' ')
    end

    def create_danthes_default_conf
      warn 'danthes.rb NOT FOUND!'
      path = File.expand_path('../../templates/danthes.rb.erb', __FILE__)
      if File.file?(path)
        template = ERB.new(File.read(path))
        stream   = StringIO.new(template.result(binding))
        upload! stream, "#{fetch(:runit_danthes_conf)}"
        info 'danthes.rb generated'
      end
    end

    task :add_default_hooks do
      after 'deploy:check', 'runit:danthes:check'
      after 'deploy:finished', 'runit:danthes:restart'
    end

    task :check do
      if fetch(:runit_danthes_default_hooks)
        invoke 'runit:setup'
        invoke 'runit:danthes:setup'
        invoke 'runit:danthes:enable'
      end
      on roles fetch(:runit_danthes_role) do
        if test "[ -d #{path_to_danthes_service_dir} ]"
          # Create danthes.rb for new deployments if not in repo
          if !fetch(:runit_danthes_conf_in_repo) && !test("[ -f #{fetch(:runit_danthes_conf)} ]")
            create_danthes_default_conf
          end
        else
          error "Danthes runit service isn't enabled."
        end
      end
    end

    desc 'Setup danthes runit service'
    task :setup do
      invoke 'runit:setup'
      # requirements
      if fetch(:runit_danthes_bind).nil?
        $stderr.puts "You should set 'runit_danthes_bind' variable."
        exit 1
      end

      on roles fetch(:runit_danthes_role) do
        if test "[ ! -d #{deploy_to}/runit/available/danthes ]"
          execute :mkdir, '-v', "#{deploy_to}/runit/available/danthes"
        end
        if test "[ ! -d #{shared_path}/tmp/danthes ]"
          execute :mkdir, '-v', "#{shared_path}/tmp/danthes"
        end
        template_path = fetch(:runit_danthes_run_template)
        if !template_path.nil? && File.exist?(template_path)
          runit_danthes_command = collect_danthes_run_command
          template           = ERB.new(File.read(template_path))
          stream             = StringIO.new(template.result(binding))
          upload! stream, "#{deploy_to}/runit/available/danthes/run"
          execute :chmod, '0755', "#{deploy_to}/runit/available/danthes/run"
        else
          error "Template from 'runit_danthes_run_template' variable isn't found: #{template_path}"
        end
      end
    end

    desc 'Enable danthes runit service'
    task :enable do
      on roles fetch(:runit_danthes_role) do
        if test "[ -d #{deploy_to}/runit/available/danthes ]"
          if test "[ -d #{deploy_to}/runit/enabled/danthes ]"
            info 'danthes runit service already enabled'
          else
            within "#{deploy_to}/runit/enabled" do
              execute :ln, '-sf', '../available/danthes', 'danthes'
            end
          end
        else
          error "Danthes runit service isn't found. You should run runit:danthes:setup."
        end
      end
    end

    desc 'Disable danthes runit service'
    task :disable do
      invoke 'runit:danthes:stop'
      on roles fetch(:runit_danthes_role) do
        if test "[ -d #{path_to_danthes_service_dir} ]"
          execute :rm, '-f', "#{path_to_danthes_service_dir}"
        else
          error "Danthes runit service isn't enabled."
        end
      end
    end

    desc 'Start danthes runit service'
    task :start do
      on roles fetch(:runit_danthes_role) do
        if test "[ -d #{path_to_danthes_service_dir} ]"
          execute "#{fetch(:runit_sv_path)} start #{path_to_danthes_service_dir}"
        else
          error "Danthes runit service isn't enabled."
        end
      end
    end

    desc 'Stop danthes runit service'
    task :stop do
      on roles fetch(:runit_danthes_role) do
        if test "[ -d #{path_to_danthes_service_dir} ]"
          execute "#{fetch(:runit_sv_path)} stop #{path_to_danthes_service_dir}"
        else
          error "Danthes runit service isn't enabled."
        end
      end
    end

    desc 'Restart danthes runit service'
    task :restart do
      on roles fetch(:runit_danthes_role) do
        if test "[ -d #{path_to_danthes_service_dir} ]"
          if test("[ -f #{fetch(:runit_danthes_pid)} ]") && test("kill -0 $( cat #{fetch(:runit_danthes_pid)} )")
            within current_path do
              execute :bundle, :exec, :pumactl, "-S #{fetch(:runit_danthes_state)} restart"
            end
          else
            info 'Danthes is not running'
            execute "#{fetch(:runit_sv_path)} start #{path_to_danthes_service_dir}"
          end
        else
          error "Danthes runit service isn't enabled."
        end
      end
    end

    desc 'Force restart danthes runit service'
    task :force_restart do
      on roles fetch(:runit_danthes_role) do
        if test "[ -d #{path_to_danthes_service_dir} ]"
          execute "#{fetch(:runit_sv_path)} start #{path_to_danthes_service_dir}"
        else
          error "Danthes runit service isn't enabled."
        end
      end
    end

    desc 'Run phased restart danthes runit service'
    task :phased_restart do
      on roles fetch(:runit_danthes_role) do
        if test "[ -d #{path_to_danthes_service_dir} ]"
          execute "#{fetch(:runit_sv_path)} 1 #{path_to_danthes_service_dir}"
        else
          error "Danthes runit service isn't enabled."
        end
      end
    end
  end
end
