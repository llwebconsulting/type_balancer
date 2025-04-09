<img src="https://www.ruby-lang.org/images/header-ruby-logo.png" width="50" align="right" alt="Ruby Logo"/>

# TypeBalancer

[![Gem Version](https://badge.fury.io/rb/type_balancer.svg)](https://badge.fury.io/rb/type_balancer)
[![CI](https://github.com/llwebconsulting/type_balancer/actions/workflows/ci.yml/badge.svg)](https://github.com/llwebconsulting/type_balancer/actions/workflows/ci.yml)
[![Ruby Coverage](https://img.shields.io/badge/ruby--coverage-78.57%25-yellow.svg)](https://github.com/llwebconsulting/type_balancer/blob/main/coverage/index.html)
[![C Coverage](https://img.shields.io/badge/c--coverage-92.4%25-brightgreen.svg)](https://github.com/llwebconsulting/type_balancer/blob/main/ext/type_balancer/README.md)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)

A Ruby gem for calculating evenly distributed positions across a dataset, with support for both pure Ruby and optimized C implementations.

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

TypeBalancer provides two implementations:
1. Pure Ruby (default) - Simple, easy to understand, and suitable for most use cases
2. Optimized C - High-performance implementation for large datasets

### Basic Usage

```ruby
# Uses default Ruby implementation
positions = TypeBalancer.calculate_positions(
  total_count: 1000,    # Total number of items
  ratio: 0.2,           # Ratio of items to select (20%)
  available_items: 200  # Optional: limit to first 200 items
)
```

### Switching Implementations

```ruby
# Switch to C implementation for better performance
TypeBalancer.implementation = :c

# Switch back to Ruby implementation
TypeBalancer.implementation = :ruby
```

## Choosing an Implementation

### Pure Ruby Implementation
- Default choice
- Suitable for most use cases
- Easy to understand and modify
- Great for development and testing
- Performs well with small to medium datasets

Use when:
- Working with small to medium datasets (< 10,000 items)
- Development and testing
- Need code that's easy to understand and modify
- Don't want to deal with C extension compilation

### C Implementation
- Optimized for performance
- Uses SIMD instructions when available
- Perfect for large datasets
- Requires C extension compilation

Use when:
- Working with large datasets (> 10,000 items)
- Performance is critical
- Processing data in batch operations
- High-throughput requirements

## Performance Comparison

Here are some benchmark results comparing the implementations:

### Small Dataset (1,000 items, 20% ratio)
```
Pure Ruby:     ~80,000 ops/sec
Integrated C:  ~75,000 ops/sec
```

### Large Dataset (100,000 items, 20% ratio)
```
Pure Ruby:     ~800 ops/sec
Integrated C:  ~850 ops/sec
```

### Very Large Dataset (1,000,000 items, 20% ratio)
```
Pure Ruby:     ~80 ops/sec
Integrated C:  ~75 ops/sec
```

Note: Performance may vary based on hardware, Ruby version, and usage of YJIT.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/llwebconsulting/type_balancer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/llwebconsulting/type_balancer/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TypeBalancer project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/llwebconsulting/type_balancer/blob/main/CODE_OF_CONDUCT.md).
