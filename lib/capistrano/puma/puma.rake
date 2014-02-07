require "erb"

namespace :runit do
  namespace :puma do
    task :map_bins do
      if Rake::Task.task_defined?("bundler:map_bins")
        fetch(:bundle_bins).push "puma"
      end
      if Rake::Task.task_defined?("rbenv:map_bins")
        fetch(:rbenv_map_bins).push "puma"
      end
    end

    if Rake::Task.task_defined?("bundler:map_bins")
      before "bundler:map_bins", "runit:puma:map_bins"
    end
    if Rake::Task.task_defined?("rbenv:map_bins")
      before "rbenv:map_bins", "runit:puma:map_bins"
    end

    desc "Setup puma runit service"
    task :setup do
      # requirements
      if fetch(:runit_puma_bind).nil?
        $stderr.puts "You should set 'runit_puma_bind' variable."
        exit 1
      end

      on roles(:app) do |host|
        if test "[ ! -d runit/available/puma ]"
          execute :mkdir, "-v", "runit/available/puma"
        end
        if test "[ ! -d #{shared_path}/tmp/puma ]"
          execute :mkdir, "-v", "#{shared_path}/tmp/puma"
        end
        template_path = fetch(:runit_puma_template)
        if !template_path.nil? && File.exist?(template_path)
          template = ERB.new(File.read(template_path))
          stream = StringIO.new(template.result(binding))
          upload! stream, "runit/available/puma/run"
          execute :chmod, "0755", "runit/available/puma/run"
        else
          error "Template from 'runit_puma_template' variable isn't found: #{template_path}"
        end
      end
    end

    desc "Enable puma runit service"
    task :enable do
      on roles(:app) do |host|
        if test "[ -d runit/available/puma ]"
          within "runit/enabled" do
            execute :ln, "-sf", "../available/puma", "puma"
          end
        else
          error "Puma runit service isn't found. You should run runit:puma:setup."
        end
      end
    end

    desc "Disable puma runit service"
    task :disable do
      invoke "runit:puma:stop"
      on roles(:app) do
        if test "[ -d runit/enabled/puma ]"
          execute :rm, "-f", "runit/enabled/puma"
        else
          error "Puma runit service isn't enabled."
        end
      end
    end

    desc "Start puma runit service"
    task :start do
      on roles(:app) do
        if test "[ -d runit/enabled/puma ]"
          execute :sv, "start", "runit/enabled/puma/"
        else
          error "Puma runit service isn't enabled."
        end
      end
    end

    desc "Stop puma runit service"
    task :stop do
      on roles(:app) do
        if test "[ -d runit/enabled/puma ]"
          execute :sv, "stop", "runit/enabled/puma/"
        else
          error "Puma runit service isn't enabled."
        end
      end
    end

    desc "Restart puma runit service"
    task :restart do
      on roles(:app) do
        if test "[ -d runit/enabled/puma ]"
          execute :sv, "restart", "runit/enabled/puma/"
        else
          error "Puma runit service isn't enabled."
        end
      end
    end

    desc "Run phased restart puma runit service"
    task :phased_restart do
      on roles(:app) do
        if test "[ -d runit/enabled/puma ]"
          execute :sv, "1", "runit/enabled/puma/"
        else
          error "Puma runit service isn't enabled."
        end
      end
    end
  end
end

namespace :load do
  task :defaults do
    set :runit_puma_run_template, File.expand_path("../run-puma.erb", __FILE__)
    set :runit_puma_workers, 1
    set :runit_puma_threads_min, 0
    set :runit_puma_threads_max, 16
    set :runit_puma_bind, nil
  end
end
