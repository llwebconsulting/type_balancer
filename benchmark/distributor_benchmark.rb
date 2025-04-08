#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'benchmark'
require 'benchmark/ips'
require_relative '../lib/type_balancer'

# Check YJIT status
YJIT_ENABLED = if ENV['RUBY_YJIT_ENABLE'] == '1'
  begin
    RubyVM::YJIT.enabled?
  rescue LoadError, NameError
    false
  end
else
  false
end
puts "YJIT Status: #{YJIT_ENABLED ? 'Enabled' : 'Not available/Disabled'}"

# Test cases with different sizes and ratios
TEST_CASES = [
  { total: 10, available: 5, ratio: 0.2 },
  { total: 10, available: 5, ratio: 0.5 },
  { total: 1_000, available: 200, ratio: 0.2 },
  { total: 1_000, available: 200, ratio: 0.5 },
  { total: 100_000, available: 20_000, ratio: 0.2 },
  { total: 100_000, available: 20_000, ratio: 0.5 }
].freeze

def validate_basic(positions, total_count)
  return false if positions.nil? || positions.empty?
  return false if positions.any? { |pos| pos >= total_count }
  true
end

def run_benchmark(test_case)
  # Create calculators outside the benchmark loop
  c_calculator = TypeBalancer::DistributionCalculator.new(test_case[:ratio])
  ruby_calculator = TypeBalancer::Distributor

  # Warm up the cache and JIT
  10.times do
    c_calculator.calculate_target_positions(test_case[:total], test_case[:available])
    ruby_calculator.calculate_target_positions(test_case[:total], test_case[:available], test_case[:ratio])
  end
  
  GC.start # Clean up before benchmarking

  # Quick validation before benchmarking - just check for error cases
  c_result = c_calculator.calculate_target_positions(
    test_case[:total],
    test_case[:available]
  )
  ruby_result = ruby_calculator.calculate_target_positions(
    test_case[:total],
    test_case[:available],
    test_case[:ratio]
  )

  unless validate_basic(c_result, test_case[:total]) && validate_basic(ruby_result, test_case[:total])
    puts "\nSkipping benchmark for total_count: #{test_case[:total]}, ratio: #{test_case[:ratio]} - invalid results detected"
    return
  end

  puts "\nBenchmarking with total_count: #{test_case[:total]}, " \
       "available_items: #{test_case[:available]}, ratio: #{test_case[:ratio]}"

  Benchmark.bm(20) do |x|
    x.report('C Extension:') do
      100.times do
        c_calculator.calculate_target_positions(
          test_case[:total],
          test_case[:available]
        )
      end
    end

    x.report('Pure Ruby:') do
      100.times do
        ruby_calculator.calculate_target_positions(
          test_case[:total],
          test_case[:available],
          test_case[:ratio]
        )
      end
    end
  end

  puts "\nBenchmark IPS (iterations per second):"
  Benchmark.ips do |x|
    x.config(time: 5, warmup: 5) # Increased warmup time

    x.report("C Extension#{YJIT_ENABLED ? ' (YJIT)' : ''}") do
      c_calculator.calculate_target_positions(
        test_case[:total],
        test_case[:available]
      )
    end

    x.report("Pure Ruby#{YJIT_ENABLED ? ' (YJIT)' : ''}") do
      ruby_calculator.calculate_target_positions(
        test_case[:total],
        test_case[:available],
        test_case[:ratio]
      )
    end

    x.compare!
  end
end

puts 'Running benchmarks...'
TEST_CASES.each do |test_case|
  run_benchmark(test_case)
end
