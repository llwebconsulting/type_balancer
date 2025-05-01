#!/usr/bin/env ruby
# frozen_string_literal: true

require 'type_balancer'
require 'yaml'
require 'json'

class LargeScaleBalanceTest
  GREEN = "\e[32m"
  RED = "\e[31m"
  YELLOW = "\e[33m"
  RESET = "\e[0m"

  def initialize
    @total_records = 500
    @type_distribution = {
      'type_a' => 250, # 50%
      'type_b' => 175, # 35%
      'type_c' => 75   # 15%
    }
  end

  def run
    puts "\n#{YELLOW}Running Large Scale Balance Test#{RESET}"
    puts "Total Records: #{@total_records}"
    puts 'Distribution:'
    @type_distribution.each do |type, count|
      puts "  #{type}: #{count} (#{(count.to_f / @total_records * 100).round(1)}%)"
    end

    test_data = generate_test_data
    run_balance_test(test_data)
  end

  private

  def generate_test_data
    items = []
    @type_distribution.each do |type, count|
      count.times do |i|
        items << { type: type, id: "#{type}_#{i + 1}" }
      end
    end
    items.shuffle
  end

  def run_balance_test(items)
    puts "\nRunning balance test..."

    # Balance the items
    balanced_items = TypeBalancer.balance(items, type_field: :type)

    # Analyze distribution in chunks
    chunk_sizes = [10, 25, 50, 100]
    chunk_sizes.each do |size|
      analyze_chunk(balanced_items, size)
    end

    # Analyze full distribution
    puts "\nFull Distribution Analysis:"
    distribution = balanced_items.map { |item| item[:type] }.tally
    distribution.each do |type, count|
      percentage = (count.to_f / balanced_items.length * 100).round(1)
      puts "#{type}: #{count} (#{percentage}%)"
    end
  end

  def analyze_chunk(items, size)
    puts "\nAnalyzing first #{size} items:"
    chunk = items.first(size)
    distribution = chunk.map { |item| item[:type] }.tally

    distribution.each do |type, count|
      percentage = (count.to_f / size * 100).round(1)
      puts "#{type}: #{count} (#{percentage}%)"
    end

    # Calculate ideal distribution for this chunk size
    ideal_distribution = calculate_ideal_distribution(size)

    # Compare with ideal
    puts "\nComparison with ideal distribution:"
    ideal_distribution.each do |type, ideal_count|
      actual_count = distribution[type] || 0
      diff = actual_count - ideal_count
      color = if diff.zero?
                GREEN
              else
                (diff.abs <= 1 ? YELLOW : RED)
              end
      puts "#{color}#{type}: Actual: #{actual_count}, Ideal: #{ideal_count.round(1)} (Diff: #{diff})#{RESET}"
    end
  end

  def calculate_ideal_distribution(chunk_size)
    total = @type_distribution.values.sum
    @type_distribution.transform_values do |count|
      (count.to_f / total) * chunk_size
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  test = LargeScaleBalanceTest.new
  test.run
end
