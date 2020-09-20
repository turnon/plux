# Plux

An easy unixsocket server

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'plux'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install plux

## Usage

```ruby
# start one and only process named 'abc', with 2 threads in it (1 thread if not specified),
# no matter the code below is called how many times in whatever processes/threads
server = Plux.worker(:abc, thread: 2) do

  # prepare thread-safe resources like mq/db, to handle requests
  def initialize
    # @db = ...
  end

  # threads call this method to deal with clients' message
  def work(msg)
    # @db << parse(msg)
  end
end

# clients connect, send msg, and close concurrently
5.times do |n|
  Thread.new do
    client = server.connect
    client.puts "hello"
    client.puts "my name is #{n}"
    client.close
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/plux. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Plux project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/plux/blob/master/CODE_OF_CONDUCT.md).
