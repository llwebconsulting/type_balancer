#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'benchmark'
require_relative '../lib/type_balancer'

# Medium-sized test case
TEST_CASE = { total: 1_000, available: 200, ratio: 0.2 }.freeze

puts "Running quick benchmark with:"
puts "- Total count: #{TEST_CASE[:total]}"
puts "- Available items: #{TEST_CASE[:available]}"
puts "- Ratio: #{TEST_CASE[:ratio]}"
puts "\n"

# Using the actual implementations from the gem
c_calculator = TypeBalancer::DistributionCalculator.new(TEST_CASE[:ratio])
ruby_calculator = TypeBalancer::Distributor

ITERATIONS = 10_000

Benchmark.bm(20) do |x|
  x.report('C Extension:') do
    ITERATIONS.times do
      c_calculator.calculate_target_positions(
        TEST_CASE[:total],
        TEST_CASE[:available]
      )
    end
  end

  x.report('Pure Ruby:') do
    ITERATIONS.times do
      ruby_calculator.calculate_target_positions(
        TEST_CASE[:total],
        TEST_CASE[:available],
        TEST_CASE[:ratio]
      )
    end
  end
end 