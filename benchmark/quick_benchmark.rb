#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'benchmark'
require_relative '../lib/type_balancer'

# Test cases of increasing size with different ratios
TEST_CASES = [
  { name: 'Tiny', total: 100, ratio: 0.1 },
  { name: 'Small', total: 1_000, ratio: 0.2 },
  { name: 'Medium', total: 10_000, ratio: 0.3 },
  { name: 'Large', total: 100_000, ratio: 0.5 }
].freeze

# Print YJIT status
if defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?
  puts "YJIT is enabled"
else
  puts "YJIT is not enabled"
end
puts

# Generate available items for each test case
TEST_CASES.each do |test|
  # Create available items as 20% more than needed
  target = (test[:total] * test[:ratio]).round
  available = (target * 1.2).round
  test[:available] = Array.new(available) { |i| i }
end

def run_benchmark_for_mode(mode)
  puts "\nBenchmarking #{mode} mode:"
  puts "==================#{mode.to_s.size.times.map { '=' }.join}="

  TypeBalancer.implementation_mode = mode

  TEST_CASES.each do |test_case|
    puts "\nRunning benchmark for #{test_case[:name]} dataset:"
    puts "- Total count: #{test_case[:total]}"
    puts "- Available items: #{test_case[:available].size}"
    puts "- Ratio: #{test_case[:ratio]}"
    puts

    # Adjust iterations based on dataset size
    iterations = case test_case[:name]
                when 'Tiny' then 100_000
                when 'Small' then 10_000
                when 'Medium' then 1_000
                when 'Large' then 100
                end

    # Warmup phase
    puts "Warming up..."
    warmup_iterations = iterations / 10
    warmup_iterations.times do
      TypeBalancer.calculate_positions(
        total_count: test_case[:total],
        ratio: test_case[:ratio],
        available_items: test_case[:available]
      )
    end
    puts "Warmup complete."
    puts

    Benchmark.bm(20) do |x|
      x.report("#{mode}:") do
        iterations.times do
          TypeBalancer.calculate_positions(
            total_count: test_case[:total],
            ratio: test_case[:ratio],
            available_items: test_case[:available]
          )
        end
      end
    end
  end
end

# Run benchmarks for each mode
[:pure_c, :pure_ruby].each do |mode|
  run_benchmark_for_mode(mode)
end 