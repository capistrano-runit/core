# capistrno-runit

## Description

capistrano-runit is a collection of various capistrano tasks that helps to manage runit services. It's useful for rails applications that uses runit to run per-user processes (unicorn, resque, sidekiq, thinking_sphinx, etc).

## Requirements

caistrano-runit requires capistrano 3.x version.
capistrano 2.x support is moved in `capistrano-2.x` branch.

## Installation

Add to `Gemfile`:
```
gem "capistrano-runit", ">= 2.0", group: "development"
```

Run:
```
$ bundle install
```

