namespace :runit do
  desc "Setup runit directories"
  task :setup do
    on roles(fetch(:runit_roles)) do
      within fetch(:deploy_to) do
        if test "[ !-d runit ]"
          execute :mkdir, "-v", "runit"
        else
          info "Directory 'runit' already exists"
        end
        %w(.env available enabled).each do |subdir|
          if test "[ !-d runit/#{subdir}"
            execute :mkdir, "-v", "runit/#{subdir}"
          else
            info "Directory 'runit/#{subdir}' already exists"
          end
        end

        execute "echo $HOME > runit/.env/HOME"
      end
    end
  end
end

namespace :load do
  task :defaults do
    set :runit_roles, fetch(:runit_roles, [:app, :db])
  end
end
