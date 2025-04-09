#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'benchmark'
require 'benchmark/ips'
require_relative '../lib/type_balancer'

# Check if YJIT is enabled
puts "YJIT enabled: #{RubyVM::YJIT.enabled? rescue false}"

# Verify native extension is available
begin
  require 'type_balancer/native'
  puts "\nNative extension loaded successfully"
rescue LoadError => e
  puts "\nERROR: Native extension not available!"
  puts "This benchmark requires the native extension to be properly compiled and loaded."
  puts "Original error: #{e.message}"
  puts "\nPossible solutions:"
  puts "1. Ensure the extension is compiled: cd ext/type_balancer && ruby extconf.rb && make"
  puts "2. Check that the compiled extension is in the correct load path"
  puts "3. Verify there are no compilation errors"
  exit 1
end

# Test data generator
def generate_test_data(size)
  types = %w[video image article]
  (0...size).map do |i|
    {
      id: i,
      type: types[i % types.size],
      title: "Item #{i}"
    }
  end
end

# Test cases with varying sizes
TEST_CASES = [
  { name: "Small Dataset", size: 10 },
  { name: "Medium Dataset", size: 1_000 },
  { name: "Large Dataset", size: 100_000 }
]

# Critical verification that we're using the correct implementation
def verify_native_implementation
  puts "\nVerifying native implementation..."
  TypeBalancer.implementation_mode = :native_struct
  
  # Try to access a method that only exists in the native extension
  begin
    TypeBalancer::Native.respond_to?(:calculate_positions_native) or raise "Native method not found"
    puts "✓ Native implementation verified"
  rescue => e
    puts "ERROR: Native implementation verification failed: #{e.message}"
    puts "The benchmark will not proceed without proper native implementation."
    exit 1
  end
end

def run_benchmark
  verify_native_implementation
  puts "\nRunning end-to-end benchmarks..."
  
  TEST_CASES.each do |test_case|
    puts "\nBenchmarking #{test_case[:name]} (#{test_case[:size]} items)"
    
    # Generate test data
    collection = generate_test_data(test_case[:size])
    
    # Warm up cache and JIT
    puts "\nWarming up..."
    10.times do
      TypeBalancer.implementation_mode = :native_struct
      TypeBalancer.balance(collection, type_field: :type)
      
      TypeBalancer.implementation_mode = :pure_ruby
      TypeBalancer.balance(collection, type_field: :type)
    end

    # Run time-based benchmark
    puts "\nTime-based benchmark (100 iterations):"
    Benchmark.bm(25) do |bm|
      bm.report("Native Struct Implementation") do
        TypeBalancer.implementation_mode = :native_struct
        100.times { TypeBalancer.balance(collection, type_field: :type) }
      end

      bm.report("Pure Ruby Implementation") do
        TypeBalancer.implementation_mode = :pure_ruby
        100.times { TypeBalancer.balance(collection, type_field: :type) }
      end
    end

    # Run iterations per second benchmark
    puts "\nIterations per second benchmark (5s runtime, 5s warmup):"
    Benchmark.ips do |bm|
      bm.config(time: 5, warmup: 5)

      bm.report("Native Struct Implementation") do
        TypeBalancer.implementation_mode = :native_struct
        TypeBalancer.balance(collection, type_field: :type)
      end

      bm.report("Pure Ruby Implementation") do
        TypeBalancer.implementation_mode = :pure_ruby
        TypeBalancer.balance(collection, type_field: :type)
      end

      bm.compare!
    end

    # Validate results match
    puts "\nValidating results are consistent..."
    TypeBalancer.implementation_mode = :native_struct
    native_result = TypeBalancer.balance(collection, type_field: :type)
    
    TypeBalancer.implementation_mode = :pure_ruby
    ruby_result = TypeBalancer.balance(collection, type_field: :type)

    puts "Results match: #{native_result.map { |i| i[:id] } == ruby_result.map { |i| i[:id] }}"
    
    # Print distribution stats
    puts "\nDistribution Stats:"
    %w[video image article].each do |type|
      native_count = native_result.count { |i| i[:type] == type }
      ruby_count = ruby_result.count { |i| i[:type] == type }
      puts "#{type.capitalize}:"
      puts "  Native: #{native_count} (#{(native_count.to_f / test_case[:size] * 100).round(2)}%)"
      puts "  Ruby: #{ruby_count} (#{(ruby_count.to_f / test_case[:size] * 100).round(2)}%)"
    end
  end
end

run_benchmark 