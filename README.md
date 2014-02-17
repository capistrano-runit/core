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

See documention for each module below.

## Modules

* [Base tasks](/lib/capistrano/runit/README.md)
* [Puma](/lib/capistrano/puma/README.md)
* [Sidekiq](/lib/capistrano/sidekiq/README.md)
