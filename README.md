<img src="https://www.ruby-lang.org/images/header-ruby-logo.png" width="50" align="right" alt="Ruby Logo"/>

# TypeBalancer

[![Gem Version](https://badge.fury.io/rb/type_balancer.svg)](https://badge.fury.io/rb/type_balancer)
[![CI](https://github.com/llwebconsulting/type_balancer/actions/workflows/ci.yml/badge.svg)](https://github.com/llwebconsulting/type_balancer/actions/workflows/ci.yml)
[![Ruby Coverage](https://img.shields.io/badge/ruby--coverage-78.57%25-yellow.svg)](https://github.com/llwebconsulting/type_balancer/blob/main/coverage/index.html)
[![C Coverage](https://img.shields.io/badge/c--coverage-92.4%25-brightgreen.svg)](https://github.com/llwebconsulting/type_balancer/blob/main/ext/type_balancer/README.md)
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
$ git clone https://github.com/llwebconsulting/type_balancer.git
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

### Implementation Selection

TypeBalancer provides both C extension and pure Ruby implementations. By default, it uses C extensions for optimal performance, but you can configure which implementation to use:

```ruby
# Configure globally to use C extensions (default)
TypeBalancer.configure do |config|
  config.use_c_extensions = true
end

# Or switch to pure Ruby implementation
TypeBalancer.configure do |config|
  config.use_c_extensions = false
end

# Then use TypeBalancer as normal
balanced_items = TypeBalancer.balance(items, type_field: :type)
```

### Quality Testing

The gem includes a comprehensive quality testing script that verifies both implementations are working correctly. To run the tests:

```bash
$ ruby examples/quality.rb
```

The quality script tests:
- C extension functionality (default implementation)
- Pure Ruby implementation
- Custom object handling
- Performance comparison between implementations
- Edge cases (empty collections, single items, etc.)
- Type ordering
- Large dataset handling (10,000+ items)

The script provides detailed output including:
- Test progress indicators
- Performance benchmarks
- Comprehensive test results summary
- Exit code 0 for success, 1 for any failures

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

TypeBalancer uses C extensions to optimize critical calculations, providing significant performance improvements over pure Ruby implementations. The gem has been tested across multiple Ruby versions (3.2.8, 3.3.7, and 3.4.2) both with and without YJIT enabled.

### Latest Benchmark Results by Ruby Version

#### Ruby 3.4.2 with YJIT
| Dataset Size | Items [Available] | C Extension Speed | Pure Ruby Speed | Performance Gain |
|-------------|-------------------|-------------------|-----------------|-----------------|
| Small | 10 [5] | 25.8M ops/sec (38.7 ns/op) | 3.8M ops/sec (260 ns/op) | 6.7x faster |
| Medium | 1,000 [200] | 23.0M ops/sec (43.5 ns/op) | 234K ops/sec (4.3 μs/op) | 98.2x faster |
| Large | 100,000 [20K] | 26.5M ops/sec (37.7 ns/op) | 3.0K ops/sec (331.8 μs/op) | 8,802x faster |

#### Ruby 3.3.7 with YJIT
| Dataset Size | Items [Available] | C Extension Speed | Pure Ruby Speed | Performance Gain |
|-------------|-------------------|-------------------|-----------------|-----------------|
| Small | 10 [5] | 28.1M ops/sec (35.6 ns/op) | 3.3M ops/sec (305.3 ns/op) | 8.6x faster |
| Medium | 1,000 [200] | 18.5M ops/sec (54.0 ns/op) | 109K ops/sec (9.2 μs/op) | 170x faster |
| Large | 100,000 [20K] | 26.9M ops/sec (37.2 ns/op) | 1.6K ops/sec (636.4 μs/op) | 17,107x faster |

#### Ruby 3.2.8 with YJIT
| Dataset Size | Items [Available] | C Extension Speed | Pure Ruby Speed | Performance Gain |
|-------------|-------------------|-------------------|-----------------|-----------------|
| Small | 10 [5] | 13.4M ops/sec (74.6 ns/op) | 2.7M ops/sec (370 ns/op) | 4.9x faster |
| Medium | 1,000 [200] | 13.8M ops/sec (72.5 ns/op) | 88K ops/sec (11.4 μs/op) | 156x faster |
| Large | 100,000 [20K] | 13.4M ops/sec (74.6 ns/op) | 879 ops/sec (1.14 ms/op) | 15,221x faster |

### Key Performance Characteristics

1. YJIT Impact:
   - Pure Ruby performance improves significantly with newer Ruby versions
   - Ruby 3.4.2 shows the best Pure Ruby performance (~3,014 ops/sec for large datasets)
   - The performance gap between C Extension and Pure Ruby decreases in newer versions

2. Version-Specific Improvements:
   - C Extension throughput nearly doubles from Ruby 3.2.8 to 3.3.7/3.4.2
   - Pure Ruby performance shows consistent improvement across versions
   - Both 3.3.7 and 3.4.2 achieve similar C Extension performance (~26.5-26.9M ops/sec)

3. Scaling Characteristics:
   - C Extension maintains near-constant performance regardless of dataset size
   - Pure Ruby performance degrades with dataset size, but less severely in newer versions
   - Largest performance gains observed with large datasets (8,802x - 17,107x faster)

The C extension achieves these improvements through:
- Direct memory access for array operations
- Optimized type comparison and grouping
- Efficient position calculation algorithms
- Minimal object allocation and garbage collection overhead

For detailed benchmark methodology and additional results, see our [Benchmark Documentation](docs/benchmarks/).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/llwebconsulting/type_balancer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/llwebconsulting/type_balancer/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TypeBalancer project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/llwebconsulting/type_balancer/blob/main/CODE_OF_CONDUCT.md).
