#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'benchmark'
require 'benchmark/ips'
require_relative '../lib/type_balancer'
require_relative '../lib/type_balancer/ruby/batch_calculator'

# Check if YJIT is enabled
puts "YJIT enabled: #{RubyVM::YJIT.enabled? rescue false}"

# Define native C API module/class
C_NATIVE_API = TypeBalancer::Native rescue nil

# Test cases with varying sizes and ratios
TEST_CASES = [
  { total_count: 10, available_items: 5, ratio: 0.2 },
  { total_count: 1_000, available_items: 200, ratio: 0.5 },
  { total_count: 100_000, available_items: 20_000, ratio: 0.2 },
  { total_count: 1_000_000, available_items: 200_000, ratio: 0.1 },
  { total_count: 10_000_000, available_items: 2_000_000, ratio: 0.05 },
  { total_count: 100_000_000, available_items: 20_000_000, ratio: 0.01 }
]

def validate_ruby_array(arr, total_count)
  arr.all? { |pos| pos.is_a?(Integer) && pos >= 0 && pos < total_count }
end

def validate_native_array(arr, total_count)
  return false unless arr.is_a?(TypeBalancer::PositionArray)
  return false unless arr.respond_to?(:size) && arr.size > 0

  # Check each position is within bounds
  (0...arr.size).all? do |i|
    pos = arr[i]
    pos.is_a?(Integer) && pos >= 0 && pos < total_count
  end
rescue StandardError
  false
end

def run_benchmark
  puts "\nRunning benchmarks..."
  
  TEST_CASES.each do |test_case|
    puts "\nBenchmarking with total_count=#{test_case[:total_count]}, ratio=#{test_case[:ratio]}"
    
    # Create calculators/modules
    c_calculator = TypeBalancer::DistributionCalculator.new(test_case[:ratio])
    ruby_calculator = TypeBalancer::Ruby::Calculator
    batch_calculator = TypeBalancer::Ruby::BatchCalculator
    
    # Create batch configuration
    batch = TypeBalancer::Ruby::BatchCalculator::PositionBatch.new(
      total_count: test_case[:total_count],
      available_count: test_case[:available_items],
      ratio: test_case[:ratio]
    )

    # Warm up cache and JIT
    10.times do
      c_calculator.calculate_target_positions(test_case[:total_count], test_case[:available_items])
      ruby_calculator.calculate_positions(total_count: test_case[:total_count], ratio: test_case[:ratio])
      batch_calculator.calculate_positions_batch(batch)
      if C_NATIVE_API
        target_count = (test_case[:total_count] * test_case[:ratio]).to_i
        target_count = test_case[:available_items] if target_count > test_case[:available_items]
        C_NATIVE_API.calculate_positions_native(target_count, test_case[:available_items])
      end
    end

    # Run time-based benchmark
    puts "\nTime-based benchmark (100 iterations):"
    Benchmark.bm(25) do |bm|
      bm.report("C Extension (Array)") do
        100.times { c_calculator.calculate_target_positions(test_case[:total_count], test_case[:available_items]) }
      end

      bm.report("Pure Ruby") do
        100.times { ruby_calculator.calculate_positions(total_count: test_case[:total_count], ratio: test_case[:ratio]) }
      end

      bm.report("Ruby Batch") do
        batch_calculator.calculate_positions_batch(batch, 100)
      end

      if C_NATIVE_API
        bm.report("C Native (Struct)") do
          100.times do
            target_count = (test_case[:total_count] * test_case[:ratio]).to_i
            target_count = test_case[:available_items] if target_count > test_case[:available_items]
            C_NATIVE_API.calculate_positions_native(target_count, test_case[:available_items])
          end
        end
      end
    end

    # Run iterations per second benchmark
    puts "\nIterations per second benchmark (5s runtime, 5s warmup):"
    Benchmark.ips do |bm|
      bm.config(time: 5, warmup: 5)

      bm.report("C Extension (Array)") do
        c_calculator.calculate_target_positions(test_case[:total_count], test_case[:available_items])
      end

      bm.report("Pure Ruby") do
        ruby_calculator.calculate_positions(total_count: test_case[:total_count], ratio: test_case[:ratio])
      end

      bm.report("Ruby Batch") do
        batch_calculator.calculate_positions_batch(batch)
      end

      if C_NATIVE_API
        bm.report("C Native (Struct)") do
          target_count = (test_case[:total_count] * test_case[:ratio]).to_i
          target_count = test_case[:available_items] if target_count > test_case[:available_items]
          C_NATIVE_API.calculate_positions_native(target_count, test_case[:available_items])
        end
      end

      bm.compare!
    end

    # Validate results
    c_result = c_calculator.calculate_target_positions(test_case[:total_count], test_case[:available_items])
    ruby_result = ruby_calculator.calculate_positions(total_count: test_case[:total_count], ratio: test_case[:ratio])
    batch_result = batch_calculator.calculate_positions_batch(batch)
    native_result = nil
    if C_NATIVE_API
      target_count = (test_case[:total_count] * test_case[:ratio]).to_i
      target_count = test_case[:available_items] if target_count > test_case[:available_items]
      native_result = C_NATIVE_API.calculate_positions_native(target_count, test_case[:available_items])
    end

    puts "\nValidation:"
    puts "C Extension (Array): #{validate_ruby_array(c_result, test_case[:total_count])}"
    puts "Pure Ruby: #{validate_ruby_array(ruby_result, test_case[:total_count])}"
    puts "Ruby Batch: #{validate_ruby_array(batch_result, test_case[:total_count])}"
    puts "C Native (Struct): #{validate_native_array(native_result, test_case[:total_count])}" if C_NATIVE_API
  end
end

run_benchmark
