<img src="https://raw.githubusercontent.com/ruby/ruby.github.io/master/images/ruby-logo.svg" width="50" align="right" alt="Ruby Logo"/>

# TypeBalancer

[![Gem Version](https://badge.fury.io/rb/type_balancer.svg)](https://badge.fury.io/rb/type_balancer)
[![CI](https://github.com/yourusername/type_balancer/actions/workflows/ci.yml/badge.svg)](https://github.com/yourusername/type_balancer/actions/workflows/ci.yml)
[![Ruby Coverage](https://img.shields.io/badge/ruby--coverage-78.57%25-yellow.svg)](https://github.com/yourusername/type_balancer/blob/main/coverage/index.html)
[![C Coverage](https://img.shields.io/badge/c--coverage-92.4%25-brightgreen.svg)](https://github.com/yourusername/type_balancer/blob/main/ext/type_balancer/README.md)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)

TypeBalancer is a Ruby gem that helps you evenly distribute items in a collection based on their types, ensuring a balanced representation of each type throughout the collection. It uses optimized C extensions for core operations, providing significant performance improvements over pure Ruby implementations.

## Installation

### In a Rails Application

Add this line to your application's Gemfile:

```ruby
gem 'type_balancer'
```

Then execute:
```bash
$ bundle install
```

### In a Ruby Application

Add this line to your Gemfile:
```ruby
source 'https://rubygems.org'
gem 'type_balancer'
```

Or install it directly:
```bash
$ gem install type_balancer
```

### Installing from Source

```bash
$ git clone https://github.com/yourusername/type_balancer.git
$ cd type_balancer
$ bundle install
$ rake compile  # Compiles C extensions
$ rake install  # Installs the gem
```

## Usage

TypeBalancer works with any collection of objects that have a type field, whether it's a method or a hash key. The gem can be used with plain Ruby objects, hashes, or in Rails applications.

```ruby
require 'type_balancer'

# Create a balancer with your collection
balancer = TypeBalancer::Balancer.new(items, type_field: :type)

# Get the balanced collection
balanced_items = balancer.call
```

For detailed examples, including:
- Basic usage with Ruby objects
- Working with hashes
- Content feed balancing
- Rails integration

See the [examples directory](examples/content_feed_balancer.rb).

### Customizing Type Order

By default, TypeBalancer will use the types in the order they first appear in the collection. You can specify a custom order:

```ruby
balancer = TypeBalancer::Balancer.new(items, 
  type_field: :type,
  types: ['video', 'image', 'article']
)
```

### Adjusting Distribution Ratio

The primary type (first type) is distributed according to a target ratio. By default, this is 0.2 (20% of positions). You can adjust this:

```ruby
# Use a custom distribution calculator with a different ratio
calculator = TypeBalancer::DistributionCalculator.new(0.3) # 30%
balancer = TypeBalancer::Balancer.new(items,
  type_field: :type,
  distribution_calculator: calculator
)
```

## C Implementation Details

The core balancing algorithm is implemented in C for performance. The implementation consists of several modules:

### Spacing Calculator
Calculates optimal spacing between items based on collection size and target count.
- `calculate_spacing`: Determines final spacing value
- `calculate_base_spacing`: Computes initial spacing
- `adjust_spacing_for_edge_cases`: Handles special cases and bounds

### Position Calculator
Calculates target positions based on spacing and collection parameters.
- `calculate_target_positions`: Main entry point for position calculation
- Handles ratio-based position count adjustment

### Position Generator
Generates actual positions based on spacing calculations.
- `generate_positions`: Creates array of positions
- Ensures positions are within bounds

### Position Array
Manages position array operations.
- `initialize_position_array`: Sets up position tracking
- `set_position`: Marks positions as used
- `is_position_available`: Checks position availability

### Position Adjuster
Adjusts positions to maintain proper spacing and bounds.
- `adjust_positions`: Ensures positions are valid and well-distributed

### Distributor
Top-level module that coordinates position calculation and adjustment.
- Integrates with Ruby through the extension interface
- Manages memory and array operations

### Gap Fillers
Efficiently fills gaps in collections using optimized algorithms:
- `SequentialFiller`: Fills gaps by cycling through each available items array
- `AlternatingFiller`: Fills gaps by alternating between primary and secondary items
- Both implementations use optimized memory management and round-robin item selection

For detailed information about all C implementations, see our [C Extension Documentation](docs/c_extensions/).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then:

- Run `bundle exec rake compile` to compile C extensions
- Run `bundle exec rake spec` to run the tests
- Run `bundle exec rubocop` to check code style
- Run `bundle exec ruby benchmark/distributor_benchmark.rb` to run performance benchmarks
- Run `bin/console` for an interactive prompt for experimentation

The development process typically involves:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
   - Add tests for any new functionality
   - Ensure all tests pass
   - Update documentation as needed
   - Compile C extensions if modified
4. Commit your changes (`git commit -am 'Add some amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Create a Pull Request

### Working with C Extensions

The gem includes C extensions for performance-critical operations. When working with these:

1. C extension source code is in `ext/type_balancer/`
2. After modifying C code:
   ```bash
   cd ext/type_balancer
   ruby extconf.rb
   make clean
   make
   ```

## Performance

TypeBalancer uses C extensions to optimize critical calculations, providing significant performance improvements over pure Ruby implementations:

### Latest Benchmark Results

| Dataset Size | Items Distribution | C Extension Speed | Pure Ruby Speed | Performance Gain |
|-------------|-------------------|------------------|----------------|-----------------|
| Small | 10 [5] | 18.4M ops/sec (54 ns/op) | 3.1M ops/sec (324 ns/op) | 6x faster |
| Medium | 1,000 [200] | 17.7M ops/sec (56 ns/op) | 150K ops/sec (6.7 μs/op) | 119x faster |
| Large | 100,000 [20K] | 17.9M ops/sec (56 ns/op) | 1.7K ops/sec (600 μs/op) | 10,727x faster |

Key Performance Characteristics:
- Dramatic performance improvement that scales with dataset size
- Nearly constant-time performance for C implementation regardless of dataset size
- Exponential performance advantage for larger collections (up to 10,727x faster)
- Extremely efficient memory and computational optimization
- Linear performance degradation in Ruby vs constant-time in C

The C extension achieves these improvements through:
- Direct memory access for array operations
- Optimized type comparison and grouping
- Efficient position calculation algorithms
- Minimal object allocation and garbage collection overhead

For detailed performance analysis and benchmarks, see our [C Extension Documentation](docs/c_extensions/distributor.md).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/type_balancer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/yourusername/type_balancer/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TypeBalancer project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/yourusername/type_balancer/blob/main/CODE_OF_CONDUCT.md).
