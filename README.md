# capistrno-runit

This gem is a collection of various capistrano tasks that helps to manage runit services. It's useful for rails applications that uses runit to run per-user processes (unicorn, resque, sidekiq, thinking_sphinx, etc).

## Requirements

caistrano-runit requires capistrano 3.x version.

## Installation

Add to `Gemfile`:
```
group :development do
  gem "capistrano", "~> 3.1"
  gem "capistrano-runit", "~> 2.0"
end
```

Run:
```
$ bundle install
```

## Usage

Add this line in `Capfile`:
```
require "capistrano/runit"
```

## Tasks

* `runit:setup` -- prepare runit directories in the project directory.

## Variables

* `runit_roles` -- what host roles uses runit to run processes. Default value: `[:app, :db]`.
* `runit_sv_path` -- Path to the runit sv binary. Default value: `/sbin/sv`

## Puma

### Usage

Add this line in `Capfile`:
```
require "capistrano/runit/puma"
```

### Tasks

* `runit:puma:setup` -- setup puma runit service.
* `runit:puma:enable` -- enable and autostart service.
* `runit:puma:disable` -- stop and disable service.
* `runit:puma:start` -- start service.
* `runit:puma:stop` -- stop service.
* `runit:puma:restart` -- restart service.
* `runit:puma:phased_restart` -- run phased restart.
* `runit:puma:force_restart` -- run forced restart.

### Variables

* `runit_puma_role` -- what host roles uses runit to run puma. Default value: `:app`
* `runit_puma_default_hooks` -- run default hooks for runit puma or not. Default value: `true`.
* `runit_puma_run_template` -- path to ERB template of `run` file. Default value: internal default template (`lib/capistrano/templates/run-puma.erb`).
* `runit_puma_workers` -- number of puma workers. Default value: 1.
* `runit_puma_threads_min` -- minimal threads to use. Default value: 0.
* `runit_puma_threads_max` -- maximal threads to use. Default value: 16.
* `runit_puma_bind` -- bind URI. Examples: tcp://127.0.0.1:8080, unix:///tmp/puma.sock. Default value: nil.
* `runit_puma_rackup` -- Path to application's rackup file. Default value: `File.join(current_path, 'config.ru')`
* `runit_puma_state`  -- Path to puma's state file. Default value: `File.join(shared_path, 'tmp', 'pids', 'puma.state')`
* `runit_puma_pid` -- Path to pid file. Default value: `File.join(shared_path, 'tmp', 'pids', 'puma.pid')`
* `runit_puma_bind` -- Puma's bind string. Default value: `File.join('unix://', shared_path, 'tmp', 'sockets', 'puma.sock')`
* `runit_puma_conf` -- Path to puma's config file. Default value: `File.join(shared_path, 'puma.rb')`
* `runit_puma_access_log` -- Path to puma's access log. Default value: `File.join(shared_path, 'log', 'puma_access.log')`
* `runit_puma_error_log` -- Path to puma's error log. Default value: `File.join(shared_path, 'log', 'puma_access.log')`
* `runit_puma_init_active_record` -- Enable or not establish ActiveRecord connection. Default value: `false`
* `runit_puma_preload_app` -- Preload application. Default value: `true`

## Sidekiq

### Usage

Add this line in `Capfile`:
```
require "capistrano/runit/sidekiq"
```

### Tasks

* `runit:sidekiq:setup` -- setup sidekiq runit service.
* `runit:sidekiq:enable` -- enable and autostart service.
* `runit:sidekiq:disable` -- stop and disable service.
* `runit:sidekiq:start` -- start service.
* `runit:sidekiq:stop` -- stop service.
* `runit:sidekiq:restart` -- restart service.

### Variables

* `runit_sidekiq_default_hooks` -- run default hooks for runit sidekiq or not. Default value: `true`.
* `runit_sidekiq_role` -- Role on where sidekiq will be running. Default value: `:app`
* `runit_sidekiq_pid` -- Pid file path. Default value: `tmp/sidekiq.pid`
* `runit_sidekiq_run_template` -- path to ERB template of `run` file. Default value: internal default template (`lib/capistrano/runit/templates/run-puma.erb`).
* `runit_sidekiq_concurrency` -- number of threads of sidekiq process. Default value: `nil`.
* `runit_sidekiq_queues` -- array of queue names. Default value: `nil`.
* `runit_sidekiq_config_path` -- relative path to config file. Default value: `nil`.
