# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  enable_coverage :branch

  add_group 'Core', 'lib/type_balancer'
  add_group 'Gap Fillers', 'lib/type_balancer/gap_fillers'

  minimum_coverage line: 90, branch: 85
  minimum_coverage_by_file line: 85, branch: 80
end

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
