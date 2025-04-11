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

[View Examples & Quality Tests](docs/quality.md) | [View Benchmark Results](docs/benchmarks/README.md)

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

For more information about the quality script and its uses, see our [quality script documentation](docs/quality.md).

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
- [Quality Script Documentation](docs/quality.md)
- [Benchmark Documentation](docs/benchmarks/README.md)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TypeBalancer project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/llwebconsulting/type_balancer/blob/main/CODE_OF_CONDUCT.md).
