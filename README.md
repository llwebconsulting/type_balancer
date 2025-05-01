<img src="https://www.ruby-lang.org/images/header-ruby-logo.png" width="50" align="right" alt="Ruby Logo"/>

# TypeBalancer

[![Gem Version](https://badge.fury.io/rb/type_balancer.svg)](https://rubygems.org/gems/type_balancer)
[![CI](https://github.com/llwebconsulting/type_balancer/actions/workflows/ci.yml/badge.svg)](https://github.com/llwebconsulting/type_balancer/actions/workflows/ci.yml)
[![Ruby Coverage](https://img.shields.io/badge/ruby--coverage-78.57%25-yellow.svg)](https://github.com/llwebconsulting/type_balancer/blob/main/coverage/index.html)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)

Imagine you have a collection of items—like blog posts—that each belong to a specific type: Articles, Images, and Videos. Typically, articles heavily outnumber the other types, which means users often have to scroll past dozens of articles before encountering a video or image. Not an ideal experience.

TypeBalancer solves this by intelligently mixing your collection based on type. You simply pass it your collection and the name of the type field, and it ensures that Images and Videos are evenly distributed alongside Articles right at the top of your feed. This way, your users get a more varied and engaging experience from the moment they start scrolling.

TypeBalancer is a sophisticated Ruby gem designed to solve the challenge of distributing different types of content across a sequence while maintaining optimal spacing and ratios. It's particularly useful for:

- **Content Management Systems**: Ensure a balanced mix of content types (videos, articles, images) in feeds
- **E-commerce**: Distribute different product categories evenly across search results
- **News Feeds**: Balance different news categories while maintaining relevance
- **Recommendation Systems**: Mix various content types while preserving user preferences

The gem uses advanced distribution algorithms to ensure that items are not only balanced by type but also maintain optimal spacing, preventing clusters of similar content while respecting specified ratios.

[View Documentation](docs/README.md) | [View Benchmark Results](docs/benchmarks/README.md)

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

# Balance items by type (uses default sliding window strategy)
balanced_items = TypeBalancer.balance(items, type_field: :type)

# Use sliding window strategy with custom window size
balanced_items = TypeBalancer.balance(items, 
  type_field: :type,
  strategy: :sliding_window,
  window_size: 25
)
```

## Balancing Collections with `TypeBalancer.balance`

The primary method for balancing collections is `TypeBalancer.balance`. This method takes an array of items and distributes them by type, ensuring optimal spacing and respecting type ratios.

### Available Strategies

TypeBalancer uses a strategy pattern to provide different balancing algorithms. Currently, the gem implements a sophisticated sliding window strategy as its default approach:

#### Sliding Window Strategy (Default)
The sliding window strategy balances items by examining a fixed-size window of items at a time (default size: 10). Within each window, it maintains the overall ratio of types while ensuring each type gets fair representation. This creates both local and global balance in your content distribution.

**When to Use Sliding Window Strategy:**
- Content feeds where users might stop scrolling at any point
- When you want to ensure diversity in any segment of your list
- When you need to maintain both local and global balance
- When you want to prevent long runs of the same type while still allowing some natural clustering

**Window Size Selection Guide:**
- Small windows (5-10): Strict local balance, ideal for shorter lists or when immediate diversity is critical
- Medium windows (15-25): Balance between local and global distribution
- Large windows (30+): More gradual transitions, better for preserving some natural clustering

```ruby
# Basic usage with default window size (10)
balanced = TypeBalancer.balance(items, type_field: :type)

# Custom window size for stricter local balance
balanced = TypeBalancer.balance(items, 
  type_field: :type,
  strategy: :sliding_window,
  window_size: 5
)

# Larger window for more gradual transitions
balanced = TypeBalancer.balance(items,
  type_field: :type,
  strategy: :sliding_window,
  window_size: 25
)

# With custom type ordering
balanced = TypeBalancer.balance(items,
  type_field: :type,
  strategy: :sliding_window,
  window_size: 15,
  type_order: %w[image video article]
)
```

The strategy system is designed to be extensible, allowing for future implementations of different balancing algorithms as needed.

### Basic Example

```ruby
items = [
  { type: 'video', title: 'Video 1' },
  { type: 'image', title: 'Image 1' },
  { type: 'article', title: 'Article 1' },
  # ...
]
balanced = TypeBalancer.balance(items, type_field: :type)
# => [ { type: 'article', ... }, { type: 'image', ... }, { type: 'video', ... }, ... ]
```

### Custom Type Order

You can specify a custom order for types using the `type_order` argument. This controls the priority of types in the balanced output.

```ruby
# Prioritize images, then videos, then articles
balanced = TypeBalancer.balance(items,
  type_field: :type,
  type_order: %w[image video article],
  strategy: :sliding_window,
  window_size: 15
)
# => [ { type: 'image', ... }, { type: 'video', ... }, { type: 'article', ... }, ... ]
```

- `type_field`: The key to use for type extraction (default: `:type`).
- `type_order`: An array of type names (as strings) specifying the desired order.
- `strategy`: The balancing strategy to use (default: `:sliding_window`).
- `window_size`: Size of the sliding window for the sliding window strategy (default: 10).

For more advanced usage and options, see [Detailed Balance Method Documentation](docs/balance.md).

## Calculating Positions Directly

In addition to balancing collections, you can use `TypeBalancer.calculate_positions` to determine optimal positions for a given type or subset of items within a sequence. This is useful for advanced scenarios where you need fine-grained control over item placement.

**Basic Example:**

```ruby
# Calculate positions for 3 items in a sequence of 10 slots
positions = TypeBalancer.calculate_positions(total_count: 10, ratio: 0.3)
# => [0, 5, 9]
```

**With Available Items:**

```ruby
# Restrict placement to specific slots
positions = TypeBalancer.calculate_positions(total_count: 10, ratio: 0.5, available_items: [0, 1, 2])
# => [0, 1, 2]
```

For more advanced usage and options, see [Detailed Position Calculation Documentation](docs/calculate_positions.md).

## Performance Characteristics

TypeBalancer is designed to handle collections of varying sizes efficiently. Here are the current performance metrics:

- Tiny collections (10 items): Microsecond-level processing (6-10μs)
- Small collections (100 items): Sub-millisecond processing (30-52μs)
- Medium collections (1,000 items): Fast processing (274-555μs)
- Large collections (10,000 items): Efficient processing (2.4-4.5ms)

Performance has been thoroughly tested across Ruby versions (3.2.8, 3.3.7, and 3.4.2). YJIT provides significant improvements (40-89% faster) with the greatest impact on medium-sized datasets. For detailed benchmarks across Ruby versions and YJIT configurations, see our [benchmark documentation](docs/benchmarks/README.md).

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

After checking out the repo, run `bin/setup` to install dependencies. Then:

1. Run `rake spec` to run the test suite
2. Run `bundle exec ruby examples/quality.rb` to run the quality checks
3. Run `rake rubocop` to check code style
4. Run `bin/console` for an interactive prompt

For more information about the gem, its features, and quality checks, see our [documentation](docs/README.md).

## Contributing

We welcome contributions to TypeBalancer! Here's how you can help:

1. **Fork the Repository**
   - Visit the [TypeBalancer repository](https://github.com/llwebconsulting/type_balancer)
   - Click the "Fork" button in the top right
   - Clone your fork locally: `git clone git@github.com:your-username/type_balancer.git`

2. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Your Changes**
   - Write tests for new functionality
   - Ensure all tests pass: `rake spec`
   - Run quality checks: `bundle exec ruby examples/quality.rb`
   - Check code style: `rake rubocop`
   - Update documentation as needed

4. **Commit Your Changes**
   ```bash
   git commit -am 'feat: add some feature'
   ```
   Please follow [conventional commits](https://www.conventionalcommits.org/) for commit messages.

5. **Push to Your Fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request**
   - Visit your fork on GitHub
   - Click "New Pull Request"
   - Ensure the base branch is `main`
   - Provide a clear description of your changes
   - Link any relevant issues

### Pull Request Requirements
- All CI checks must pass
- Test coverage should be maintained or improved
- Documentation should be updated as needed
- Code should follow the project's style guide
- Quality script should pass without new issues

For more detailed information about our development process and tools:
- [Documentation](docs/README.md)
- [Benchmark Documentation](docs/benchmarks/README.md)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TypeBalancer project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/llwebconsulting/type_balancer/blob/main/CODE_OF_CONDUCT.md).
