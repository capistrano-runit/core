namespace :runit do
  desc "Setup runit directories"
  task :setup do
    on roles fetch(:runit_roles) do
      within fetch(:deploy_to) do
        if test "[ ! -d #{deploy_to}/runit ]"
          execute :mkdir, "-v", "#{deploy_to}/runit"
        else
          info "Directory 'runit' already exists"
        end
        %w(.env available enabled).each do |subdir|
          if test "[ ! -d #{deploy_to}/runit/#{subdir} ]"
            execute :mkdir, "-v", "#{deploy_to}/runit/#{subdir}"
          else
            info "Directory 'runit/#{subdir}' already exists"
          end
        end

        execute "echo $HOME > #{deploy_to}/runit/.env/HOME"
      end
    end
  end
end

namespace :load do
  task :defaults do
    set :runit_roles, fetch(:runit_roles, [:app, :db])
    set :runit_sv_path, '/sbin/sv'
  end
end
