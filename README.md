<img src="https://www.ruby-lang.org/images/header-ruby-logo.png" width="50" align="right" alt="Ruby Logo"/>

# TypeBalancer

[![Gem Version](https://badge.fury.io/rb/type_balancer.svg)](https://badge.fury.io/rb/type_balancer)
[![CI](https://github.com/llwebconsulting/type_balancer/actions/workflows/ci.yml/badge.svg)](https://github.com/llwebconsulting/type_balancer/actions/workflows/ci.yml)
[![Ruby Coverage](https://img.shields.io/badge/ruby--coverage-78.57%25-yellow.svg)](https://github.com/llwebconsulting/type_balancer/blob/main/coverage/index.html)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)

A Ruby gem for balancing and distributing items of different types across a sequence while maintaining optimal spacing.

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

```ruby
items = [
  { type: 'video', title: 'Video 1' },
  { type: 'image', title: 'Image 1' },
  { type: 'article', title: 'Article 1' },
  # ... more items
]

# Balance items by type
balanced_items = TypeBalancer.balance(items, type_field: :type)
```

## Performance Characteristics

TypeBalancer is designed to handle collections of varying sizes efficiently. Here are the current performance metrics:

- Tiny collections (10 items): Microsecond-level processing (9-14μs)
- Small collections (100 items): Sub-millisecond processing (~450-500μs)
- Medium collections (1,000 items): Fast processing (~20-21ms)
- Large collections (10,000 items): Efficient processing (~193-209ms)

Performance has been thoroughly tested across Ruby versions (3.2.8, 3.3.7, and 3.4.2). YJIT provides significant improvements for small datasets (up to 51% faster for tiny collections) with varying impact on larger datasets. For detailed benchmarks across Ruby versions and YJIT configurations, see our [benchmark documentation](docs/benchmarks/README.md).

### Recommendations

- Suitable for real-time processing of collections up to 10,000 items
- Excellent performance for content management systems and feed generation
- Thread-safe and memory-efficient
- If you need to process very large collections (>10,000 items), consider batch processing or open an issue for guidance

## Features

- Maintains optimal spacing between items of the same type
- Supports custom type fields
- Preserves original item data
- Thread-safe
- Zero dependencies

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/llwebconsulting/type_balancer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/llwebconsulting/type_balancer/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TypeBalancer project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/llwebconsulting/type_balancer/blob/main/CODE_OF_CONDUCT.md).
