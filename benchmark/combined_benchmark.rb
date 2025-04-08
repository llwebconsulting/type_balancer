#!/usr/bin/env ruby
# frozen_string_literal: true

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

# Test cases with different sizes
SMALL_COLLECTION  = { total: 10, available: 5, ratio: 0.2 }.freeze
MEDIUM_COLLECTION = { total: 1_000, available: 200, ratio: 0.2 }.freeze
LARGE_COLLECTION  = { total: 100_000, available: 20_000, ratio: 0.2 }.freeze

def run_benchmark(test_case)
  c_calculator = TypeBalancer::DistributionCalculator.new(test_case[:ratio])
  ruby_calculator = TypeBalancer::Distributor # Using actual Ruby implementation

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
    x.config(time: 5, warmup: 2)

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
[SMALL_COLLECTION, MEDIUM_COLLECTION, LARGE_COLLECTION].each do |test_case|
  run_benchmark(test_case)
end 