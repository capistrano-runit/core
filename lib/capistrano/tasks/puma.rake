require 'erb'

namespace :load do
  task :defaults do
    set :runit_puma_role, -> { :app }
    set :runit_puma_default_hooks, -> { true }
    set :runit_puma_run_template, File.expand_path('../../templates/run-puma.erb', __FILE__)
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

    def path_to_puma_service_dir
      "#{deploy_to}/runit/enabled/puma/"
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
      array << SSHKit.config.default_env.map { |k, v| "#{k.upcase}=\"#{v}\"" }.join(' ')
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
      if fetch(:runit_puma_default_hooks)
        invoke 'runit:setup'
        invoke 'runit:puma:setup'
        invoke 'runit:puma:enable'
      end
      on roles fetch(:runit_puma_role) do
        if test "[ -d #{path_to_puma_service_dir} ]"
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
      invoke 'runit:setup'
      # requirements
      if fetch(:runit_puma_bind).nil?
        $stderr.puts "You should set 'runit_puma_bind' variable."
        exit 1
      end

      on roles fetch(:runit_puma_role) do
        if test "[ ! -d #{deploy_to}/runit/available/puma ]"
          execute :mkdir, '-v', "#{deploy_to}/runit/available/puma"
        end
        if test "[ ! -d #{shared_path}/tmp/puma ]"
          execute :mkdir, '-v', "#{shared_path}/tmp/puma"
        end
        template_path = fetch(:runit_puma_run_template)
        if !template_path.nil? && File.exist?(template_path)
          runit_puma_command = collect_puma_run_command
          template           = ERB.new(File.read(template_path))
          stream             = StringIO.new(template.result(binding))
          upload! stream, "#{deploy_to}/runit/available/puma/run"
          execute :chmod, '0755', "#{deploy_to}/runit/available/puma/run"
        else
          error "Template from 'runit_puma_run_template' variable isn't found: #{template_path}"
        end
      end
    end

    desc 'Enable puma runit service'
    task :enable do
      on roles fetch(:runit_puma_role) do
        if test "[ -d #{deploy_to}/runit/available/puma ]"
          if test "[ -d #{deploy_to}/runit/enabled/puma ]"
            info 'puma runit service already enabled'
          else
            within "#{deploy_to}/runit/enabled" do
              execute :ln, '-sf', '../available/puma', 'puma'
            end
          end
        else
          error "Puma runit service isn't found. You should run runit:puma:setup."
        end
      end
    end

    desc 'Disable puma runit service'
    task :disable do
      invoke 'runit:puma:stop'
      on roles fetch(:runit_puma_role) do
        if test "[ -d #{path_to_puma_service_dir} ]"
          execute :rm, '-f', "#{path_to_puma_service_dir}"
        else
          error "Puma runit service isn't enabled."
        end
      end
    end

    desc 'Start puma runit service'
    task :start do
      on roles fetch(:runit_puma_role) do
        if test "[ -d #{path_to_puma_service_dir} ]"
          execute "#{fetch(:runit_sv_path)} start #{path_to_puma_service_dir}"
        else
          error "Puma runit service isn't enabled."
        end
      end
    end

    desc 'Stop puma runit service'
    task :stop do
      on roles fetch(:runit_puma_role) do
        if test "[ -d #{path_to_puma_service_dir} ]"
          execute "#{fetch(:runit_sv_path)} stop #{path_to_puma_service_dir}"
        else
          error "Puma runit service isn't enabled."
        end
      end
    end

    desc 'Restart puma runit service'
    task :restart do
      on roles fetch(:runit_puma_role) do
        if test "[ -d #{path_to_puma_service_dir} ]"
          if test("[ -f #{fetch(:runit_puma_pid)} ]") && test("kill -0 $( cat #{fetch(:runit_puma_pid)} )")
            within current_path do
              execute :bundle, :exec, :pumactl, "-S #{fetch(:runit_puma_state)} restart"
            end
          else
            info 'Puma is not running'
            execute "#{fetch(:runit_sv_path)} start #{path_to_puma_service_dir}"
          end
        else
          error "Puma runit service isn't enabled."
        end
      end
    end

    desc 'Force restart puma runit service'
    task :force_restart do
      on roles fetch(:runit_puma_role) do
        if test "[ -d #{path_to_puma_service_dir} ]"
          execute "#{fetch(:runit_sv_path)} start #{path_to_puma_service_dir}"
        else
          error "Puma runit service isn't enabled."
        end
      end
    end

    desc 'Run phased restart puma runit service'
    task :phased_restart do
      on roles fetch(:runit_puma_role) do
        if test "[ -d #{path_to_puma_service_dir} ]"
          execute "#{fetch(:runit_sv_path)} 1 #{path_to_puma_service_dir}"
        else
          error "Puma runit service isn't enabled."
        end
      end
    end
  end
end
