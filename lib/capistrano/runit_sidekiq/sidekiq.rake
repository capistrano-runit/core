require "erb"

namespace :load do
  task :defaults do
    set :runit_sidekiq_run_template, File.expand_path('../run-sidekiq.erb', __FILE__)
    set :runit_sidekiq_concurrency, nil
    set :runit_sidekiq_pid, -> { 'tmp/sidekiq.pid' }
    set :runit_sidekiq_queues, nil
    set :runiq_sidekiq_config_path, nil
    set :runit_sidekiq_default_hooks, -> { true }
    set :runit_sidekiq_role, -> { :app }
    set :runit_sidekiqctl_cmd, -> {}
    # Rbenv and RVM integration
    set :rbenv_map_bins, fetch(:rbenv_map_bins).to_a.concat(%w{ sidekiq sidekiqctl })
    set :rvm_map_bins, fetch(:rvm_map_bins).to_a.concat(%w{ sidekiq sidekiqctl })
  end
end

namespace :deploy do
  before :starting, :runit_check_sidekiq_hooks do
    invoke 'runit:sidekiq:add_default_hooks' if fetch(:runit_sidekiq_default_hooks)
  end
end

namespace :runit do
  namespace :sidekiq do
    # Helpers

    def path_to_sidekiq_service_dir
      "#{deploy_to}/runit/enabled/sidekiq/"
    end

    def collect_sidekiq_run_command
      array = []
      collect_default_sidekiq_params(array)
      collect_concurrency_sidekiq_params(array)
      collect_queues_sidekiq_params(array)
      collect_log_sidekiq_param(array)
      collect_pid_sidekiq_param(array)
      collect_config_sidekiq_param(array)
      array.compact.join(' ')
    end

    def sidekiq_environment
      @sidekiq_environment ||= fetch(:rack_env, fetch(:rails_env, 'production'))
    end

    def collect_default_sidekiq_params(array)
      array << SSHKit.config.default_env.map { |k, v| "#{k.upcase}=\"#{v}\"" }.join('')
      array << "exec #{SSHKit.config.command_map[:bundle]} exec sidekiq"
      array << "-e #{sidekiq_environment}"
      array << "-g #{fetch(:application)}"
    end

    def collect_concurrency_sidekiq_params(array)
      concurrency = fetch(:runit_sidekiq_concurrency)
      return unless concurrency
      array << "-c #{concurrency}"
    end

    def collect_queues_sidekiq_params(array)
      queues = fetch(:runit_sidekiq_queues)
      if queues && queues.is_a?(::Array)
        queues.map do |q|
          array << "-q #{q}" if q.is_a?(::String)
        end
      end
    end

    def collect_config_sidekiq_param(array)
      if config_path = fetch(:runiq_sidekiq_config_path)
        array << "-C #{config_path}"
      end
    end

    def collect_log_sidekiq_param(array)
      array << "-L #{File.join(current_path, "log", "sidekiq.#{sidekiq_environment}.log")}"
    end

    def collect_pid_sidekiq_param(array)
      array << "-P #{pid_full_path(fetch(:runit_sidekiq_pid))}"
    end

    def pid_full_path(pid_path)
      if pid_path.start_with?("/")
        pid_path
      else
        "#{current_path}/#{pid_path}"
      end
    end

    task :add_default_hooks do
      after 'deploy:starting', 'runit:sidekiq:quiet'
      after 'deploy:updated', 'runit:sidekiq:stop'
      after 'deploy:reverted', 'runit:sidekiq:stop'
      after 'deploy:published', 'runit:sidekiq:start'
    end

    desc "Setup sidekiq runit service"
    task :setup do
      invoke 'runit:setup'
      on roles fetch(:runit_sidekiq_role) do
        if test "[ ! -d #{deploy_to}/runit/available/sidekiq ]"
          execute :mkdir, "-v", "#{deploy_to}/runit/available/sidekiq"
        end
        template_path = fetch(:runit_sidekiq_run_template)
        if !template_path.nil? && File.exist?(template_path)
          runit_sidekiq_command = collect_sidekiq_run_command
          template = ERB.new(File.read(template_path))
          stream = StringIO.new(template.result(binding))
          upload! stream, "#{deploy_to}/runit/available/sidekiq/run"
          execute :chmod, "0755", "#{deploy_to}/runit/available/sidekiq/run"
        else
          error "Template from 'runit_sidekiq_run_template' variable isn't found: #{template_path}"
        end
      end
    end

    desc "Enable sidekiq runit service"
    task :enable do
      on roles fetch(:runit_sidekiq_role) do
        if test "[ -d #{deploy_to}/runit/available/sidekiq ]"
          within "#{deploy_to}/runit/enabled" do
            execute :ln, "-sf", "../available/sidekiq", "sidekiq"
          end
        else
          error "Sidekiq runit service isn't found. You should run runit:sidekiq:setup."
        end
      end
    end

    desc "Disable sidekiq runit service"
    task :disable do
      invoke "runit:sidekiq:stop"
      on roles fetch(:runit_sidekiq_role) do
        if test "[ -d #{path_to_sidekiq_service_dir} ]"
          execute :rm, "-f", "#{path_to_sidekiq_service_dir}"
        else
          error "Sidekiq runit service isn't enabled."
        end
      end
    end

    desc "Start sidekiq runit service"
    task :start do
      on roles fetch(:runit_sidekiq_role) do
        if test "[ -d #{path_to_sidekiq_service_dir} ]"
          execute "#{fetch(:runit_sv_path)} start #{path_to_sidekiq_service_dir}"
        else
          error "Sidekiq runit service isn't enabled."
        end
      end
    end

    desc "Stop sidekiq runit service"
    task :stop do
      on roles fetch(:runit_sidekiq_role) do
        if test "[ -f #{pid_full_path(fetch(:runit_sidekiq_pid))} ]"
          if test "[ -d #{path_to_sidekiq_service_dir} ]"
            execute "#{fetch(:runit_sv_path)} stop #{path_to_sidekiq_service_dir}"
          else
            error "Sidekiq runit service isn't enabled."
          end
        else
          info "Sidekiq is not running yet"
        end
      end
    end

    desc "Restart sidekiq runit service"
    task :restart do
      on roles fetch(:runit_sidekiq_role) do
        if test "[ -d #{path_to_sidekiq_service_dir} ]"
          execute "#{fetch(:runit_sv_path)} restart #{path_to_sidekiq_service_dir}"
        else
          error "Sidekiq runit service isn't enabled."
        end
      end
    end

    desc "Quiet sidekiq (stop accepting new work)"
    task :quiet do
      on roles fetch(:runit_sidekiq_role) do
        if test "[ -f #{pid_full_path(fetch(:runit_sidekiq_pid))} ]"
          within current_path do
            if fetch(:sidekiqctl_cmd)
              execute fetch(:sidekiqctl_cmd), 'quiet', "#{pid_full_path(fetch(:runit_sidekiq_pid))}"
            else
              execute :bundle, :exec, :sidekiqctl, 'quiet', "#{pid_full_path(fetch(:runit_sidekiq_pid))}"
            end
          end
        end
      end
    end
  end
end

