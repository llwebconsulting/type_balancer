#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'benchmark'
require_relative '../lib/type_balancer'
require 'ffi'

# Print Ruby and YJIT information
puts "Ruby version: #{RUBY_VERSION}"
puts "YJIT enabled: #{RubyVM::YJIT.enabled? rescue false}"
puts

# Test cases representing real-world scenarios
TEST_CASES = [
  { name: 'Tiny (Blog posts)', total_count: 100, available_items: 20 },
  { name: 'Small (Product catalog)', total_count: 1_000, available_items: 200 },
  { name: 'Medium (E-commerce inventory)', total_count: 10_000, available_items: 2_000 },
  { name: 'Large (User database)', total_count: 100_000, available_items: 20_000 },
  { name: 'Very Large (Analytics)', total_count: 1_000_000, available_items: 200_000 }
].freeze

# Different ratios to test
RATIOS = [0.1, 0.2, 0.3, 0.5].freeze

# Module to handle direct C calls via FFI
module DirectCCalculator
  extend FFI::Library
  ffi_lib File.expand_path('../../lib/type_balancer/type_balancer.bundle', __FILE__)
  
  class PositionBatch < FFI::Struct
    layout :ratio, :double,
           :total_count, :long,
           :positions, :pointer,
           :size, :size_t
  end
  
  attach_function :calculate_positions_batch, [:pointer], :int
end

def run_benchmarks(test_case, ratio)
  puts "\nTesting #{test_case[:name]} dataset with ratio #{ratio}:"
  puts "- Total count: #{test_case[:total_count]}"
  puts "- Available items: #{test_case[:available_items]}\n\n"

  # Adjust iterations based on dataset size
  iterations = case test_case[:name]
               when /Tiny/ then 10_000
               when /Small/ then 5_000
               when /Medium/ then 1_000
               when /Large/ then 100
               when /Very Large/ then 10
               else 1_000
               end

  warmup_iterations = [iterations / 10, 100].min
  
  # Warmup phase
  puts "Warming up..."
  warmup_iterations.times do
    # Ruby implementation
    TypeBalancer.implementation = :ruby
    TypeBalancer.calculate_positions(
      total_count: test_case[:total_count],
      ratio: ratio,
      available_items: test_case[:available_items]
    )

    # C implementation
    TypeBalancer.implementation = :c
    TypeBalancer.calculate_positions(
      total_count: test_case[:total_count],
      ratio: ratio,
      available_items: test_case[:available_items]
    )

    # Direct C implementation
    positions = FFI::MemoryPointer.new(:long, test_case[:available_items])
    batch = DirectCCalculator::PositionBatch.new
    batch[:ratio] = ratio
    batch[:total_count] = test_case[:total_count]
    batch[:positions] = positions
    batch[:size] = test_case[:available_items]
    DirectCCalculator.calculate_positions_batch(batch)
  end
  puts "Warmup complete.\n\n"

  # GC stats before benchmark
  GC.start
  gc_stats_before = GC.stat

  # Benchmark phase
  results = Benchmark.bm do |x|
    # Ruby implementation
    TypeBalancer.implementation = :ruby
    x.report("Pure Ruby:    ") do
      iterations.times do
        TypeBalancer.calculate_positions(
          total_count: test_case[:total_count],
          ratio: ratio,
          available_items: test_case[:available_items]
        )
      end
    end

    # C implementation
    TypeBalancer.implementation = :c
    x.report("Integrated C: ") do
      iterations.times do
        TypeBalancer.calculate_positions(
          total_count: test_case[:total_count],
          ratio: ratio,
          available_items: test_case[:available_items]
        )
      end
    end

    # Direct C implementation
    x.report("Direct C:     ") do
      iterations.times do
        positions = FFI::MemoryPointer.new(:long, test_case[:available_items])
        batch = DirectCCalculator::PositionBatch.new
        batch[:ratio] = ratio
        batch[:total_count] = test_case[:total_count]
        batch[:positions] = positions
        batch[:size] = test_case[:available_items]
        DirectCCalculator.calculate_positions_batch(batch)
      end
    end
  end

  # GC stats after benchmark
  gc_stats_after = GC.stat
  gc_runs = gc_stats_after[:minor_gc_count] - gc_stats_before[:minor_gc_count]
  heap_pages_growth = gc_stats_after[:heap_allocated_pages] - gc_stats_before[:heap_allocated_pages]

  puts "\nGC Statistics:"
  puts "- GC runs during benchmark: #{gc_runs}"
  puts "- Heap pages growth: #{heap_pages_growth}\n\n"

  # Calculate operations per second
  ruby_ops = iterations / results[0].real
  c_ops = iterations / results[1].real
  direct_c_ops = iterations / results[2].real

  puts "Operations per second:"
  puts "- Pure Ruby: #{ruby_ops.round(2)}"
  puts "- Integrated C: #{c_ops.round(2)}"
  puts "- Direct C: #{direct_c_ops.round(2)}\n\n"

  puts "Relative Performance:"
  puts "- Integrated C vs Ruby: #{(c_ops / ruby_ops).round(2)}x"
  puts "- Direct C vs Ruby: #{(direct_c_ops / ruby_ops).round(2)}x"
  puts "- Direct C vs Integrated C: #{(direct_c_ops / c_ops).round(2)}x"
end

# Run benchmarks for each test case and ratio
TEST_CASES.each do |test_case|
  RATIOS.each do |ratio|
    run_benchmarks(test_case, ratio)
  end
end 