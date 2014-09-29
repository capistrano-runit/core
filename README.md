# capistrano-runit-core

Base core capistrano3 module for managing various services via runit supervisor.

## Installation

Add to `Gemfile`:
```
group :development do
  gem "capistrano-runit-core", "~> 0.1.0"
end
```

Run:
```
$ bundle install
```

## runit setup

We need to create specific runit service for our whole application:
Create service folder inside `/etc/sv`:

```bash
mkdir /etc/sv/runsvdir-your_application
mkdir /etc/sv/runsvdir-your_application/log
```

Create run shell script `/etc/sv/runsvdir-your_application/run`:

```bash
#!/bin/sh
exec 2>&1
exec chpst -udeployer runsvdir /home/deployer/apps/your_application/runit/enabled
```

In current example expected what you deploying with `deployer` user to the `/home/deployer/apps/your_application` folder.

Create log run shell script `/etc/sv/runsvdir-your_application/log/run`:

```bash
#!/bin/sh
exec svlogd -tt /var/log/runsvdir-your_application
```

Create log folder:

```bash
mkdir /var/log/runsvdir-your_application
```

And make this scripts executable:

```bash
chmod a+x /etc/sv/runsvdir-your_application/run /etc/sv/runsvdir-your_application/log/run
```

And after this we will need to make symlink in `/etc/service/`

```bash
ln -s /etc/sv/runsvdir-your_application /etc/service/runsvdir-your_application
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


