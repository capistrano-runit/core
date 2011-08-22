Capistrano::Configuration.instance(true).load do
  _cset :runit_dir, defer { "#{deploy_to}/runit" }

  namespace :runit do
    desc "Setup runit directories"
    task :setup, :roles => :app do
      run "[ -d #{runit_dir}/.env ] || mkdir -p #{runit_dir}/.env"
      run "echo $HOME > #{runit_dir}/.env/HOME"
      run "[ -d #{runit_dir}/available ] || mkdir -p #{runit_dir}/available"
      run "[ -d #{runit_dir}/enabled ] || mkdir -p #{runit_dir}/enabled"
    end
  end
end
