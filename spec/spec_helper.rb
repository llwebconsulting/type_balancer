# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/c_tests/'
  add_filter '/ext/'
  add_filter '/examples/'
  enable_coverage :branch

  add_group 'Core', 'lib/type_balancer'
  add_group 'Gap Fillers', 'lib/type_balancer/gap_fillers'
  add_group 'C Extensions', 'ext/type_balancer'

  minimum_coverage line: 80, branch: 75
  minimum_coverage_by_file line: 80, branch: 75
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
