<img src="https://www.ruby-lang.org/images/header-ruby-logo.png" width="50" align="right" alt="Ruby Logo"/>

# TypeBalancer

[![Gem Version](https://badge.fury.io/rb/type_balancer.svg)](https://badge.fury.io/rb/type_balancer)
[![CI](https://github.com/llwebconsulting/type_balancer/actions/workflows/ci.yml/badge.svg)](https://github.com/llwebconsulting/type_balancer/actions/workflows/ci.yml)
[![Ruby Coverage](https://img.shields.io/badge/ruby--coverage-78.57%25-yellow.svg)](https://github.com/llwebconsulting/type_balancer/blob/main/coverage/index.html)
[![C Coverage](https://img.shields.io/badge/c--coverage-92.4%25-brightgreen.svg)](https://github.com/llwebconsulting/type_balancer/blob/main/ext/type_balancer/README.md)
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

TypeBalancer is designed to handle collections of varying sizes. Here are the current performance metrics:

- Small collections (10-100 items): Very fast, processing in under 1ms
- Medium collections (1,000 items): Good performance, ~50ms processing time
- Large collections (10,000 items): ~4.3-4.7 seconds processing time

Performance varies slightly across Ruby versions (tested on 3.2.8, 3.3.7, and 3.4.2). YJIT provides marginal improvements (2-3%) for larger datasets.

### Recommendations

- For optimal performance, we recommend processing collections of up to 1,000 items at a time
- For larger datasets, consider breaking them into smaller batches
- If you need to process very large collections (>10,000 items), please open an issue - optimizing for larger datasets is our current priority

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
