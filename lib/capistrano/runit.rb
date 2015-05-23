module Capistrano
  module Runit
    def service_dir_for(service)
      ::File.join(deploy_to, 'runit', 'available', service)
    end

    def enabled_service_dir_for(service)
      ::File.join(deploy_to, 'runit', 'enabled', service)
    end

    def env_variables
      ::SSHKit.config.default_env.map { |k, v| "#{k.upcase}=\"#{v}\"" }.join(' ')
    end

    def upload_runit_run_file(_runit_command, template_path, dest)
      template = ERB.new(File.read(template_path))
      stream   = StringIO.new(template.result(binding))
      upload! stream, dest
      execute :chmod, '0755', dest
    end

    def pid_full_path(pid_path)
      if pid_path.start_with?('/')
        pid_path
      else
        "#{shared_path}/#{pid_path}"
      end
    end

    def service_running?(service)
      service_dir   = enabled_service_dir_for(service)
      supervise_dir = ::File.join(service_dir, 'supervise')
      stat_file     = ::File.join(supervise_dir, 'stat')
      if test("[ -d #{supervise_dir} ]") && test("[ -f #{stat_file} ]")
        capture(:cat, stat_file).chomp == 'run'
      else
        false
      end
    end

    def check_service(service, namespace = nil)
      if fetch("runit_#{service}_default_hooks".to_sym)
        ::Rake::Task['runit:setup'].invoke
        service = "#{service}:#{namespace}" if namespace
        ::Rake::Task["runit:#{service}:setup"].invoke
        ::Rake::Task["runit:#{service}:enable"].invoke
      end
    end

    def setup_service(service, run_command)
      service_dir  = service_dir_for(service)
      template_key = "runit_#{service}_run_template".to_sym
      on roles fetch("runit_#{service}_role".to_sym) do
        if test "[ ! -d #{service_dir} ]"
          execute :mkdir, '-v', service_dir
        end
        template_path = fetch(template_key, ::File.expand_path('../templates/run.erb', __FILE__))
        if !template_path.nil? && File.exist?(template_path)
          upload_runit_run_file(
            run_command,
            template_path,
            ::File.join(service_dir, 'run')
          )
        else
          error "Template from '#{template_key}' variable isn't found: #{template_path}"
        end
      end
    end

    def enable_service(service)
      service_dir         = service_dir_for(service)
      enabled_service_dir = enabled_service_dir_for(service)
      on roles fetch("runit_#{service}_role".to_sym) do
        if test "[ -d #{service_dir} ]"
          if test "[ -d #{enabled_service_dir} ]"
            info "'#{service}' runit service already enabled"
          else
            execute :ln, '-snf', service_dir, enabled_service_dir
          end
        else
          error "'#{service}' runit service isn't found. You should run runit:#{service}:setup first."
        end
      end
    end

    def disable_service(service)
      ::Rake::Task["runit:#{service}:stop"].invoke
      enabled_service_dir = enabled_service_dir_for(service)
      on roles fetch("runit_#{service}_role".to_sym) do
        if test "[ -d #{enabled_service_dir}"
          execute :rm, '-f', enabled_service_dir
        else
          error "'#{service}' runit service isn't enabled."
        end
      end
    end

    def start_service(service, timeout = nil)
      on roles fetch("runit_#{service}_role".to_sym) do
        runit_execute_command(service, 'start', timeout)
      end
    end

    def stop_service(service, pidfile = true, timeout = nil)
      pid_path = pid_full_path(fetch("runit_#{service}_pid".to_sym)) if pidfile
      on roles fetch("runit_#{service}_role".to_sym) do
        if pidfile
          if test "[ -f #{pid_path} ]" && service_running?(service)
            runit_execute_command(service, 'stop', timeout)
          else
            info "'#{service}' is not running yet"
          end
        else
          if service_running?(service)
            runit_execute_command(service, 'stop', timeout)
          else
            info "'#{service}' is not running yet"
          end
        end
      end
    end

    def restart_service(service, timeout = nil)
      on roles fetch("runit_#{service}_role".to_sym) do
        runit_execute_command(service, 'restart', timeout)
      end
    end

    def kill_hup_service(service)
      on roles fetch("runit_#{service}_role".to_sym) do
        runit_execute_command(service, 'hup')
      end
    end

    def runit_execute_command(service, command, timeout = nil)
      # check timeout type
      unless timeout.instance_of?(NilClass) || (timeout.is_a?(Integer) && timeout >= 0)
        raise ArgumentError.new("'timeout' argument in '#runit_execute_command' method must be nil or positive integer.")
      end

      enabled_service_dir = enabled_service_dir_for(service)
      if test "[ -d #{enabled_service_dir} ]"
        execute "#{host.fetch(:runit_sv_path)} #{"-w #{timeout}" unless timeout.nil?} #{command} #{enabled_service_dir}"
      else
        error "'#{service}' runit service isn't enabled."
      end
    end
  end
end

load File.expand_path('../tasks/runit.rake', __FILE__)
