# Base runit tasks

## Usage

Add this line in `Capfile`:
```
require "capistrano/runit"
```

## Tasks

* `runit:setup` -- prepare runit direcotires in the project directory.

## Variables

* `runit_roles` -- what host roles uses runit to run processes. Default value: `[:app, :db]`.
* `runit_sv_path` -- Path to the runit sv binary. Default value: `/sbin/sv`
