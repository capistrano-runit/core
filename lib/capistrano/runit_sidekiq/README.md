# Sidekiq

## Usage

Add this line in `Capfile`:
```
require "capistrano/sidekiq"
```

## Tasks

* `runit:sidekiq:setup` -- setup sidekiq runit service.
* `runit:sidekiq:enable` -- enable and autostart service.
* `runit:sidekiq:disable` -- stop and disable service.
* `runit:sidekiq:start` -- start service.
* `runit:sidekiq:stop` -- stop service.
* `runit:sidekiq:restart` -- restart service.

## Variables

* `runit_sidekiq_default_hooks` -- run default hooks for runit sidekiq or not. Default value: `true`.
* `runit_sidekiq_role` -- Role on where sidekiq will be running. Default value: `:app`
* `runit_sidekiq_pid` -- Pid file path. Default value: `tmp/sidekiq.pid`
* `runit_sidekiq_run_template` -- path to ERB template of `run` file. Default value: internal default template (`lib/capistrano/runit/templates/run-puma.erb`).
* `runit_sidekiq_concurrency` -- number of threads of sidekiq process. Default value: `nil`.
* `runit_sidekiq_queues` -- array of queue names. Default value: `nil`.
* `runit_sidekiq_config_path` -- relative path to config file. Default value: `nil`.
