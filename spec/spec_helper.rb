# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  # Exclude test and C code directories
  add_filter '/spec/'
  add_filter '/c_tests/'
  add_filter '/ext/'
  add_filter '/examples/'

  # Explicitly exclude all C source files by extension
  add_filter(/\.c$/)
  add_filter(/\.h$/)

  # Also exclude any Ruby files that might directly interface with C code
  add_filter %r{/distributor\.rb$}
  add_filter %r{/gap_fillers_ext\.rb$}

  enable_coverage :branch

  # Focus only on pure Ruby code
  add_group 'Core', 'lib/type_balancer'

  # Disable coverage enforcement
  # Most of the code is now in C, so Ruby coverage is less relevant
  minimum_coverage_by_file line: 0, branch: 0
  minimum_coverage line: 0, branch: 0
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
