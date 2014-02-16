require "erb"

namespace :runit do
  namespace :sidekiq do
    task :map_bins do
      if Rake::Task.task_defined?("bundler:map_bins")
        fetch(:bundle_bins).push "sidekiq"
      end
      if Rake::Task.task_defined?("rbenv:map_bins")
        fetch(:rbenv_map_bins).push "sidekiq"
      end
    end

    if Rake::Task.task_defined?("bundler:map_bins")
      before "bundler:map_bins", "runit:sidekiq:map_bins"
    end
    if Rake::Task.task_defined?("rbenv:map_bins")
      before "rbenv:map_bins", "runit:sidekiq:map_bins"
    end

    desc "Setup sidekiq runit service"
    task :setup do
      on roles(:app) do |host|
        if test "[ ! -d runit/available/sidekiq ]"
          execute :mkdir, "-v", "runit/available/sidekiq"
        end
        if test "[ ! -d #{shared_path}/tmp/sidekiq ]"
          execute :mkdir, "-v", "#{shared_path}/tmp/sidekiq"
        end
        template_path = fetch(:runit_sidekiq_run_template)
        if !template_path.nil? && File.exist?(template_path)
          template = ERB.new(File.read(template_path))
          stream = StringIO.new(template.result(binding))
          upload! stream, "runit/available/sidekiq/run"
          execute :chmod, "0755", "runit/available/sidekiq/run"
        else
          error "Template from 'runit_sidekiq_run_template' variable isn't found: #{template_path}"
        end
      end
    end

    desc "Enable sidekiq runit service"
    task :enable do
      on roles(:app) do |host|
        if test "[ -d runit/available/sidekiq ]"
          within "runit/enabled" do
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
      on roles(:app) do
        if test "[ -d runit/enabled/sidekiq ]"
          execute :rm, "-f", "runit/enabled/sidekiq"
        else
          error "Sidekiq runit service isn't enabled."
        end
      end
    end

    desc "Start sidekiq runit service"
    task :start do
      on roles(:app) do
        if test "[ -d runit/enabled/sidekiq ]"
          execute :sv, "start", "runit/enabled/sidekiq/"
        else
          error "Sidekiq runit service isn't enabled."
        end
      end
    end

    desc "Stop sidekiq runit service"
    task :stop do
      on roles(:app) do
        if test "[ -d runit/enabled/sidekiq ]"
          execute :sv, "stop", "runit/enabled/sidekiq/"
        else
          error "Sidekiq runit service isn't enabled."
        end
      end
    end

    desc "Restart sidekiq runit service"
    task :restart do
      on roles(:app) do
        if test "[ -d runit/enabled/sidekiq ]"
          execute :sv, "restart", "runit/enabled/sidekiq/"
        else
          error "Sidekiq runit service isn't enabled."
        end
      end
    end
  end
end

namespace :load do
  task :defaults do
    set :runit_sidekiq_run_template, File.expand_path("../run-sidekiq.erb", __FILE__)
    set :runit_sidekiq_processes, 4
    set :runit_sidekiq_queues, ["default"]
  end
end
