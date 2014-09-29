# capistrano-runit-core

## 0.1.0

* Extract all supported services to separate gems
* Rename gem from capistrano-runit to capistrano-runit-core

# capistrano-runit
## 2.0.0.rc1 (unreleased)

* Add sidekiq module.
* Add puma module.
* Drop Capistrano 2.x support.

## 1.1.4 2014-02-06

* Added 'runit_unicorn_before_fork_code' variable for unicorn recipe.

## 1.1.3 2013-04-19

* Added recipes for sidekiq.
* Fixed: runit:setup should run on servers with db-role too.
* Added recipes for thinking-sphinx.
* Use rails_env variable instead of hardwired 'production' in run-unicorn.

## 1.1.2 2011-11-05

* Added double quotes for environment variables values.

## 1.1.1 2011-11-05

* default_environment hash was added in templates (special usefull for rbenv).

## 1.1.0 2011-10-23

* Bugfixes.
* Added Resque recipe.

## 1.0

* Initial release.
