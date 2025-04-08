#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'benchmark'
require_relative '../lib/type_balancer'
require 'ffi'

# Print Ruby and YJIT information
puts "Ruby version: #{RUBY_VERSION}"
puts "YJIT enabled: #{defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?}"
puts

# Test cases representing real-world scenarios
TEST_CASES = [
  { name: 'Tiny (Blog posts)', total: 100, available: 20, ratio: 0.2 },
  { name: 'Small (Product catalog)', total: 1_000, available: 200, ratio: 0.2 },
  { name: 'Medium (E-commerce inventory)', total: 10_000, available: 2_000, ratio: 0.2 },
  { name: 'Large (User database)', total: 100_000, available: 20_000, ratio: 0.2 },
  { name: 'Very Large (Analytics)', total: 1_000_000, available: 200_000, ratio: 0.2 }
].freeze

# Different ratios to test
RATIOS = [0.1, 0.2, 0.3, 0.5].freeze

# Module to handle direct C calls via FFI
module DirectCCalculator
  extend FFI::Library
  ffi_lib File.expand_path('../../lib/type_balancer/type_balancer.bundle', __FILE__)
  
  class PositionBatch < FFI::Struct
    layout :total_count, :long,
           :available_count, :long,
           :ratio, :double
  end
  
  attach_function :calculate_positions_batch, [:pointer, :int, :pointer, :pointer], :int
end

def run_benchmarks(test_case, ratio)
  puts "\nTesting #{test_case[:name]} dataset with ratio #{ratio}:"
  puts "- Total count: #{test_case[:total]}"
  puts "- Available items: #{test_case[:available]}"

  # Adjust iterations based on dataset size
  iterations = case test_case[:name]
               when /Tiny/ then 10_000
               when /Small/ then 5_000
               when /Medium/ then 1_000
               when /Large/ then 100
               when /Very Large/ then 10
               else 1_000
               end

  # Initialize calculators
  c_calculator = TypeBalancer::DistributionCalculator.new(ratio)
  ruby_calculator = TypeBalancer::Distributor

  # Prepare batch data for direct C calls
  batch = DirectCCalculator::PositionBatch.new
  batch[:total_count] = test_case[:total]
  batch[:available_count] = test_case[:available]
  batch[:ratio] = ratio

  # Warmup phase
  puts "\nWarming up..."
  warmup_iterations = [iterations / 10, 100].min
  warmup_iterations.times do
    c_calculator.calculate_target_positions(
      test_case[:total],
      test_case[:available]
    )
    ruby_calculator.calculate_target_positions(
      test_case[:total],
      test_case[:available],
      ratio
    )
    # Warmup direct C calls
    result_size = FFI::MemoryPointer.new(:int)
    positions = FFI::MemoryPointer.new(:long, test_case[:total])
    DirectCCalculator.calculate_positions_batch(batch, 1, positions, result_size)
  end
  puts "Warmup complete."

  # Memory usage before
  gc_stat_before = GC.stat

  results = Benchmark.bm(20) do |x|
    x.report('Integrated C:') do
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
          ratio
        )
      end
    end

    x.report('Direct C (Batch):') do
      # Process all iterations in a single C call
      result_size = FFI::MemoryPointer.new(:int)
      positions = FFI::MemoryPointer.new(:long, test_case[:total])
      DirectCCalculator.calculate_positions_batch(batch, iterations, positions, result_size)
    end
  end

  # Memory usage after
  gc_stat_after = GC.stat
  gc_runs = gc_stat_after[:count] - gc_stat_before[:count]
  heap_growth = gc_stat_after[:heap_allocated_pages] - gc_stat_before[:heap_allocated_pages]

  puts "\nGC Statistics:"
  puts "- GC runs during benchmark: #{gc_runs}"
  puts "- Heap pages growth: #{heap_growth}"

  # Calculate operations per second
  integrated_c_ops = iterations / results[0].real
  ruby_ops = iterations / results[1].real
  direct_c_ops = iterations / results[2].real

  puts "\nOperations per second:"
  puts "- Integrated C: #{integrated_c_ops.round(2)}"
  puts "- Pure Ruby: #{ruby_ops.round(2)}"
  puts "- Direct C (Batch): #{direct_c_ops.round(2)}"
  puts "\nRelative Performance:"
  puts "- Integrated C vs Ruby: #{(integrated_c_ops/ruby_ops).round(2)}x"
  puts "- Direct C vs Ruby: #{(direct_c_ops/ruby_ops).round(2)}x"
  puts "- Direct C vs Integrated C: #{(direct_c_ops/integrated_c_ops).round(2)}x"
end

# Run benchmarks for each test case and ratio
TEST_CASES.each do |test_case|
  RATIOS.each do |ratio|
    run_benchmarks(test_case, ratio)
  end
end 