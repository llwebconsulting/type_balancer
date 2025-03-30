# TypeBalancer

[![Gem Version](https://badge.fury.io/rb/type_balancer.svg)](https://badge.fury.io/rb/type_balancer)
[![CI](https://github.com/yourusername/type_balancer/actions/workflows/ci.yml/badge.svg)](https://github.com/yourusername/type_balancer/actions/workflows/ci.yml)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)

TypeBalancer is a Ruby gem that helps you evenly distribute items in a collection based on their types, ensuring a balanced representation of each type throughout the collection.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
$ bundle add type_balancer
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
$ gem install type_balancer
```

## Usage

TypeBalancer works with any collection of objects that have a type field, whether it's a method or a hash key. Here's a basic example:

```ruby
require 'type_balancer'

# Example with objects that respond to a type method
class Item
  attr_reader :type, :name
  
  def initialize(type, name)
    @type = type
    @name = name
  end
end

items = [
  Item.new('video', 'Video 1'),
  Item.new('video', 'Video 2'),
  Item.new('image', 'Image 1'),
  Item.new('image', 'Image 2'),
  Item.new('image', 'Image 3'),
  Item.new('strip', 'Strip 1')
]

# Create a balancer with the collection and specify the type field
balancer = TypeBalancer::Balancer.new(items, type_field: :type)

# Get the balanced collection
balanced_items = balancer.call

# The result will have videos distributed evenly throughout,
# with images and strips alternating in between
```

You can also work with hashes:

```ruby
items = [
  { type: 'video', name: 'Video 1' },
  { type: 'video', name: 'Video 2' },
  { type: 'image', name: 'Image 1' },
  { type: 'image', name: 'Image 2' },
  { type: 'strip', name: 'Strip 1' }
]

# Works with both string and symbol keys
balancer = TypeBalancer::Balancer.new(items, type_field: :type)
balanced_items = balancer.call
```

### Customizing Type Order

By default, TypeBalancer will use the types in the order they first appear in the collection. You can specify a custom order:

```ruby
# Specify the order of types
balancer = TypeBalancer::Balancer.new(items, 
  type_field: :type,
  types: ['video', 'image', 'strip']
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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then:

- Run `bundle exec rake spec` to run the tests
- Run `bundle exec rubocop` to check code style
- Run `bin/console` for an interactive prompt for experimentation

The development process typically involves:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
   - Add tests for any new functionality
   - Ensure all tests pass
   - Update documentation as needed
4. Commit your changes (`git commit -am 'Add some amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Create a Pull Request

### Running Tests

The test suite uses RSpec. To run all tests with coverage reporting:

```bash
bundle exec rspec
```

### Code Style

We follow the standard Ruby style guide enforced by RuboCop. To check your code:

```bash
bundle exec rubocop
```

To release a new version:
1. Update the version number in `version.rb`
2. Run `bundle exec rake release`
   - This will create a git tag for the version
   - Push git commits and tags
   - Push the `.gem` file to [rubygems.org](https://rubygems.org)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/type_balancer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/yourusername/type_balancer/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TypeBalancer project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/yourusername/type_balancer/blob/main/CODE_OF_CONDUCT.md).
