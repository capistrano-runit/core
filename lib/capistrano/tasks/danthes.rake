require 'erb'
include ::Capistrano::Runit

namespace :load do
  task :defaults do
    set :runit_danthes_role, -> { :app }
    set :runit_danthes_default_hooks, -> { true }
    set :runit_danthes_run_template, File.expand_path('../../templates/run.erb', __FILE__)
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
      enabled_service_dir_for('danthes')
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
      array << env_variables
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
      check_service('danthes')
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
      # requirements
      if fetch(:runit_puma_bind).nil?
        $stderr.puts "You should set 'runit_puma_bind' variable."
        exit 1
      end
      setup_service('danthes', collect_danthes_run_command)
    end

    desc 'Enable danthes runit service'
    task :enable do
      enable_service('danthes')
    end

    desc 'Disable danthes runit service'
    task :disable do
      disable_service('danthes')
    end

    desc 'Start danthes runit service'
    task :start do
      start_service('danthes')
    end

    desc 'Stop danthes runit service'
    task :stop do
      stop_service('danthes')
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
      restart_service('danthes')
    end

    desc 'Run phased restart danthes runit service'
    task :phased_restart do
      kill_hup_service('danthes')
    end
  end
end
