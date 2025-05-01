# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  # Exclude test, benchmark, and example directories
  add_filter '/spec/'
  add_filter '/benchmark/'
  add_filter '/examples/'
  add_filter 'examples/quality.rb'

  enable_coverage :branch

  # Focus only on pure Ruby code
  add_group 'Core', 'lib/type_balancer'

  # TODO: Re-enable per-file coverage requirements once we've had a chance to improve coverage
  # minimum_coverage_by_file line: 75, branch: 55

  # Overall coverage requirements
  minimum_coverage line: 80, branch: 60
end

# Ensure C extension is built and loaded
require 'bundler/setup'
require 'type_balancer'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    # Reset and register default strategies before each test
    TypeBalancer::StrategyFactory.instance_variable_set(:@strategies, {})
    TypeBalancer::StrategyFactory.instance_variable_set(:@default_strategy, nil)
    TypeBalancer::StrategyFactory.register(:sliding_window, TypeBalancer::Strategies::SlidingWindowStrategy)
    TypeBalancer::StrategyFactory.default_strategy = :sliding_window
  end
end
