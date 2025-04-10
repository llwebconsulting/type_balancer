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

  # Set minimum coverage requirements
  minimum_coverage_by_file line: 75, branch: 55
  minimum_coverage line: 85, branch: 75
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
end
