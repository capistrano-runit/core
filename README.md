# capistrno-runit

This gem is a collection of various capistrano tasks that helps to manage runit services. It's useful for rails applications that uses runit to run per-user processes (unicorn, resque, sidekiq, thinking_sphinx, etc).

## Requirements

caistrano-runit requires capistrano 3.x version.
capistrano 2.x support is moved in `capistrano-2.x` branch.

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

### runit:setup

Create runit directories in `deploy_to` directory:
```
runit
runit/available
runit/enabled
runit/.env
```

Create file `PROJECT/runit/.env/HOME` that consists value of `HOME` environment variable.

#### Variables

* `runit_roles` -- what host roles uses runit to run processes. Default value: `[:app, :db]`.
