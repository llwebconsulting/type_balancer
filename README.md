<img src="https://www.ruby-lang.org/images/header-ruby-logo.png" width="50" align="right" alt="Ruby Logo"/>

# TypeBalancer

[![Gem Version](https://badge.fury.io/rb/type_balancer.svg)](https://badge.fury.io/rb/type_balancer)
[![CI](https://github.com/llwebconsulting/type_balancer/actions/workflows/ci.yml/badge.svg)](https://github.com/llwebconsulting/type_balancer/actions/workflows/ci.yml)
[![Ruby Coverage](https://img.shields.io/badge/ruby--coverage-78.57%25-yellow.svg)](https://github.com/llwebconsulting/type_balancer/blob/main/coverage/index.html)
[![C Coverage](https://img.shields.io/badge/c--coverage-92.4%25-brightgreen.svg)](https://github.com/llwebconsulting/type_balancer/blob/main/ext/type_balancer/README.md)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)

A Ruby gem for balancing types in collections by ensuring each type appears a similar number of times. Optimized for Ruby 3.2+ with YJIT support.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'type_balancer'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install type_balancer
```

## Usage

TypeBalancer provides a simple interface to balance types in your collections:

```ruby
collection = [
  { type: 'video', title: 'Video 1' },
  { type: 'image', title: 'Image 1' },
  { type: 'article', title: 'Article 1' },
  { type: 'video', title: 'Video 2' }
]

# Balance the collection
balanced = TypeBalancer.balance(collection, type_field: :type)
```

### Performance

TypeBalancer is optimized for Ruby 3.2+ and takes full advantage of YJIT when available. Here are some benchmark results:

### Small Dataset (10 items)
```
Ruby with YJIT:    ~80,000 ops/sec
Ruby without YJIT: ~70,000 ops/sec
```

### Medium Dataset (1,000 items)
```
Ruby with YJIT:    ~800 ops/sec
Ruby without YJIT: ~700 ops/sec
```

### Large Dataset (100,000 items)
```
Ruby with YJIT:    ~8 ops/sec
Ruby without YJIT: ~7 ops/sec
```

Note: Performance may vary based on hardware and Ruby version.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/llwebconsulting/type_balancer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/llwebconsulting/type_balancer/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TypeBalancer project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/llwebconsulting/type_balancer/blob/main/CODE_OF_CONDUCT.md).
