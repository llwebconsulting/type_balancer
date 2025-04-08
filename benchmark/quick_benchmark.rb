#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'benchmark'
require_relative '../lib/type_balancer'

# Test cases of increasing size
TEST_CASES = [
  { name: 'Small', total: 1_000, available: 200, ratio: 0.2 },
  { name: 'Medium', total: 10_000, available: 2_000, ratio: 0.2 },
  { name: 'Large', total: 100_000, available: 20_000, ratio: 0.2 },
  { name: 'Very Large', total: 1_000_000, available: 200_000, ratio: 0.2 }
].freeze

# Using the actual implementations from the gem
c_calculator = TypeBalancer::DistributionCalculator.new(0.2)
ruby_calculator = TypeBalancer::Distributor

# Print YJIT status
if defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?
  puts "YJIT is enabled"
else
  puts "YJIT is not enabled"
end
puts

TEST_CASES.each do |test_case|
  puts "\nRunning benchmark for #{test_case[:name]} dataset:"
  puts "- Total count: #{test_case[:total]}"
  puts "- Available items: #{test_case[:available]}"
  puts "- Ratio: #{test_case[:ratio]}"
  puts

  # Adjust iterations based on dataset size
  iterations = case test_case[:name]
               when 'Small' then 10_000
               when 'Medium' then 1_000
               when 'Large' then 100
               when 'Very Large' then 10
               end

  # Warmup phase
  puts "Warming up..."
  warmup_iterations = iterations / 10
  warmup_iterations.times do
    c_calculator.calculate_target_positions(
      test_case[:total],
      test_case[:available]
    )
    ruby_calculator.calculate_target_positions(
      test_case[:total],
      test_case[:available],
      test_case[:ratio]
    )
  end
  puts "Warmup complete."
  puts

  Benchmark.bm(20) do |x|
    x.report('C Extension:') do
      iterations.times do
        c_calculator.calculate_target_positions(
          test_case[:total],
          test_case[:available]
        )
      end
    end

    x.report('Pure Ruby:') do
      iterations.times do
        ruby_calculator.calculate_target_positions(
          test_case[:total],
          test_case[:available],
          test_case[:ratio]
        )
      end
    end
  end
end 