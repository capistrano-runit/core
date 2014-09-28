require 'erb'
include ::Capistrano::Runit

namespace :load do
  task :defaults do
    set :runit_puma_role, -> { :app }
    set :runit_puma_default_hooks, -> { true }
    set :runit_puma_run_template, File.expand_path('../../templates/run.erb', __FILE__)
    set :runit_puma_workers, 1
    set :runit_puma_threads_min, 0
    set :runit_puma_threads_max, 16
    set :runit_puma_rackup, -> { File.join(current_path, 'config.ru') }
    set :runit_puma_state, -> { File.join(shared_path, 'tmp', 'pids', 'puma.state') }
    set :runit_puma_pid, -> { File.join(shared_path, 'tmp', 'pids', 'puma.pid') }
    set :runit_puma_bind, -> { File.join('unix://', shared_path, 'tmp', 'sockets', 'puma.sock') }
    set :runit_puma_conf, -> { File.join(shared_path, 'puma.rb') }
    set :runit_puma_conf_in_repo, -> { false }
    set :runit_puma_access_log, -> { File.join(shared_path, 'log', 'puma_access.log') }
    set :runit_puma_error_log, -> { File.join(shared_path, 'log', 'puma_error.log') }
    set :runit_puma_init_active_record, false
    set :runit_puma_preload_app, true
    # Rbenv and RVM integration
    set :rbenv_map_bins, fetch(:rbenv_map_bins).to_a.concat(%w(puma pumactl))
    set :rvm_map_bins, fetch(:rvm_map_bins).to_a.concat(%w(puma pumactl))
  end
end

namespace :deploy do
  before :starting, :runit_check_puma_hooks do
    invoke 'runit:puma:add_default_hooks' if fetch(:runit_puma_default_hooks)
  end
end

namespace :runit do
  namespace :puma do

    def puma_enabled_service_dir
      enabled_service_dir_for('puma')
    end

    def puma_service_dir
      service_dir_for('puma')
    end

    def template_puma(from, to)
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

    def collect_puma_run_command
      array = []
      array << env_variables
      array << "exec #{SSHKit.config.command_map[:bundle]} exec puma"
      puma_conf_path = if fetch(:runit_puma_conf_in_repo)
                         "#{release_path}/config/puma.rb"
                       else
                         fetch(:runit_puma_conf)
                       end
      array << "-C #{puma_conf_path}"
      array.compact.join(' ')
    end

    def create_puma_default_conf
      warn 'puma.rb NOT FOUND!'
      path = File.expand_path('../../templates/puma.rb.erb', __FILE__)
      if File.file?(path)
        template = ERB.new(File.read(path))
        stream   = StringIO.new(template.result(binding))
        upload! stream, "#{fetch(:runit_puma_conf)}"
        info 'puma.rb generated'
      end
    end

    task :add_default_hooks do
      after 'deploy:check', 'runit:puma:check'
      after 'deploy:finished', 'runit:puma:restart'
    end

    task :check do
      check_service('puma')
      on roles fetch(:runit_puma_role) do
        if test "[ -d #{puma_enabled_service_dir} ]"
          # Create puma.rb for new deployments if not in repo
          if !fetch(:runit_puma_conf_in_repo) && !test("[ -f #{fetch(:runit_puma_conf)} ]")
            create_puma_default_conf
          end
        else
          error "Puma runit service isn't enabled."
        end
      end
    end

    desc 'Setup puma runit service'
    task :setup do
      # requirements
      if fetch(:runit_puma_bind).nil?
        $stderr.puts "You should set 'runit_puma_bind' variable."
        exit 1
      end
      setup_service('puma', collect_sidekiq_run_command)
    end

    desc 'Enable puma runit service'
    task :enable do
      enable_service('puma')
    end

    desc 'Disable puma runit service'
    task :disable do
      disable_service('puma')
    end

    desc 'Start puma runit service'
    task :start do
      start_service('puma')
    end

    desc 'Stop puma runit service'
    task :stop do
      stop_service('puma')
    end

    desc 'Restart puma runit service'
    task :restart do
      on roles fetch(:runit_puma_role) do
        if test "[ -d #{puma_enabled_service_dir} ]"
          if test("[ -f #{fetch(:runit_puma_pid)} ]") && test("kill -0 $( cat #{fetch(:runit_puma_pid)} )")
            within current_path do
              execute :bundle, :exec, :pumactl, "-S #{fetch(:runit_puma_state)} restart"
            end
          else
            info 'Puma is not running'
            if test("[ -f #{fetch(:runit_puma_pid)} ]")
              info 'Removing broken pid file'
              execute :rm, '-f', fetch(:runit_puma_pid)
            end
            execute "#{fetch(:runit_sv_path)} start #{puma_enabled_service_dir}"
          end
        else
          error "Puma runit service isn't enabled."
        end
      end
    end

    desc 'Force restart puma runit service'
    task :force_restart do
      restart_service('puma')
    end

    desc 'Run phased restart puma runit service'
    task :phased_restart do
      kill_hup_service('puma')
    end
  end
end
