# Puma

## Usage

Add this line in `Capfile`:
```
require "capistrano/runit_puma"
```

## Tasks

* `runit:puma:setup` -- setup puma runit service.
* `runit:puma:enable` -- enable and autostart service.
* `runit:puma:disable` -- stop and disable service.
* `runit:puma:start` -- start service.
* `runit:puma:stop` -- stop service.
* `runit:puma:restart` -- restart service.
* `runit:puma:phased_restart` -- run phased restart.

## Variables

* `runit_puma_run_template` -- path to ERB template of `run` file. Default value: internal default template (`lib/capistrano/runit/templates/run-puma.erb`).
* `runit_puma_workers` -- number of puma workers. Default value: 1.
* `runit_puma_threads_min` -- minimal threads to use. Default value: 0.
* `runit_puma_threads_max` -- maximal threads to use. Default value: 16.
* `runit_puma_bind` -- bind URI. Examples: tcp://127.0.0.1:8080, unix:///tmp/puma.sock. Default value: nil.
