# JobEnqueueLogger

[![Build Status](https://github.com/fatkodima/job_enqueue_logger/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/fatkodima/job_enqueue_logger/actions/workflows/ci.yml)

Log background jobs enqueued by your application (additionally with backtraces). Helps with debugging, or just generally understanding what's going on under the hood. Useful for finding where to start when making changes to a large application.

This is very much a development and debugging tool; it is not recommended to use this in a production environment as it is monkey-patching the respective job queuing implementations. You have been warned - use at your own risk.

## Example

When the job is enqueued within the guts of the application, the log line is generated:

```
Enqueued AvatarThumbnailsJob (jid=578b3d10fc5403f97ee0a8e1) to Sidekiq(default) with arguments: 1092412064
```

Or with backtraces enabled:

```
Enqueued AvatarThumbnailsJob (jid=578b3d10fc5403f97ee0a8e1) to Sidekiq(default) with arguments: 1092412064
↳ app/models/user.rb:421:in `generate_avatar_thumbnails'
  app/services/user_creator.rb:21:in `call'
  app/controllers/users_controller.rb:49:in `create'
```

## Requirements

Requires ruby > 2.7.

This gem supports most common job queuing backends:

* [Sidekiq](https://github.com/sidekiq/sidekiq) >= 6.5.0
* [Resque](https://github.com/resque/resque) >= 2.0.0
* [DelayedJob](https://github.com/collectiveidea/delayed_job) >= 4.1.5
* [SuckerPunch](https://github.com/brandonhilkert/sucker_punch) >= 3.0.0
* [Que](https://github.com/que-rb/que) >= 2.0.0

If you need support for older rubies or older versions of queuing backends (or additional backends), [open an issue](https://github.com/fatkodima/job_enqueue_logger/issues/new).

## Installation

Add this line to your application's Gemfile:

```ruby
# Add this *after* your job queuing gem of choice
gem 'job_enqueue_logger', group: :development
```

And then execute:

```sh
$ bundle
```

Or install it yourself as:

```sh
$ gem install job_enqueue_logger
```

## Configuration

You can override the following default options:

```ruby
JobEnqueueLogger.configure do |config|
  # Controls the contents of the printed backtrace.
  # Is set to default Rails.backtrace_cleaner, when the gem is used in the Rails app.
  config.backtrace_cleaner = ->(backtrace) { backtrace }

  # Controls whether to print backtraces. Set to `true` to print backtraces, or
  # a number to limit how many lines to print.
  config.backtrace = false
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fatkodima/job_enqueue_logger.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
