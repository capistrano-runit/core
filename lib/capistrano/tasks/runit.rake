namespace :runit do
  desc 'Setup runit directories'
  task :setup do
    on roles fetch(:runit_roles) do
      within fetch(:deploy_to) do
        if test "[ ! -d #{deploy_to}/runit ]"
          execute :mkdir, '-v', "#{deploy_to}/runit"
        else
          info "Directory 'runit' already exists"
        end
        %w(.env available enabled).each do |subdir|
          if test "[ ! -d #{deploy_to}/runit/#{subdir} ]"
            execute :mkdir, '-v', "#{deploy_to}/runit/#{subdir}"
          else
            info "Directory 'runit/#{subdir}' already exists"
          end
        end

        execute "echo $HOME > #{deploy_to}/runit/.env/HOME"
      end
    end
  end

  task :hook do
    on roles fetch(:runit_roles, [:app, :db]) do
      with path: "#{fetch(:runit_sv_search_path)}:$PATH" do
        set :runit_sv_path, capture(:which, :sv)
      end
    end
  end

end

Capistrano::DSL.stages.each do |stage|
  after stage, 'runit:hook'
end

namespace :load do
  task :defaults do
    set :runit_roles, fetch(:runit_roles, [:app, :db])
    set :runit_sv_search_path, '/sbin:/usr/sbin'
  end
end
