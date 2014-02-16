# Sidekiq

## Usage

Add this line in `Capfile`:
```
require "capistrano/sidekiq"
```

## Tasks

* `runit:sidekiq:setup` -- setup puma runit service.
* `runit:sidekiq:enable` -- enable and autostart service.
* `runit:sidekiq:disable` -- stop and disable service.
* `runit:sidekiq:start` -- start service.
* `runit:sidekiq:stop` -- stop service.
* `runit:sidekiq:restart` -- restart service.

## Variables

* `runit_sidekiq_run_template` -- path to ERB template of `run` file. Default value: internal default template (`lib/capistrano/runit/templates/run-puma.erb`).
* `runit_sidekiq_processes` -- number of simultaneous workers. Default value: 4.
* `runit_sidekiq_queues` -- array of queue names. Default value: ["default"].
