#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "benchmark/ips"
require_relative "../lib/type_balancer"

# Print Ruby and platform info
puts "Ruby version: #{RUBY_VERSION}"
puts "RUBY_PLATFORM: #{RUBY_PLATFORM}"
puts "YJIT enabled: #{RubyVM.const_defined?(:YJIT) && RubyVM::YJIT.enabled?}"

# Test data generator
def generate_test_data(size)
  types = %w[video image article]
  Array.new(size) do |i|
    {
      id: i,
      type: types[i % types.size],
      title: "Item #{i}"
    }
  end
end

# Test cases with different dataset sizes
TEST_CASES = [
  { name: "Tiny Dataset", size: 10 },
  { name: "Small Dataset", size: 100 },
  { name: "Medium Dataset", size: 1_000 },
  { name: "Large Dataset", size: 10_000 }
]

def run_benchmark
  puts "\nRunning benchmarks..."
  types = %w[video image article]

  TEST_CASES.each do |test_case|
    puts "\nBenchmarking #{test_case[:name]} (#{test_case[:size]} items)"
    collection = generate_test_data(test_case[:size])

    # Single warmup run to ensure everything is loaded
    TypeBalancer.balance(collection, type_field: :type)

    # Run benchmark
    Benchmark.ips do |bm|
      # Adjust warmup/time based on dataset size
      warmup_time = test_case[:size] <= 100 ? 1 : 2
      bench_time = test_case[:size] <= 100 ? 2 : 3

      bm.config(time: bench_time, warmup: warmup_time)
      bm.report("Ruby Implementation") do
        TypeBalancer.balance(collection, type_field: :type)
      end
    end

    # Print distribution stats for verification
    result = TypeBalancer.balance(collection, type_field: :type)
    # Flatten batches into a single array
    flattened_result = result.flatten
    puts "\nDistribution Stats:"
    types.each do |type|
      count = flattened_result.count { |i| i[:type] == type }
      puts "#{type.capitalize}: #{count} (#{(count.to_f / test_case[:size] * 100).round(2)}%)"
    end
  end
end

run_benchmark
