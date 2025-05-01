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
    @window_sizes = [10, 25, 50, 100]
  end

  def run
    puts "\n#{YELLOW}Running Large Scale Balance Test#{RESET}"
    puts "Total Records: #{@total_records}"
    puts 'Distribution:'
    @type_distribution.each do |type, count|
      puts "  #{type}: #{count} (#{(count.to_f / @total_records * 100).round(1)}%)"
    end

    test_data = generate_test_data

    # Test default strategy
    puts "\n#{YELLOW}Testing Default Strategy (Sliding Window)#{RESET}"
    run_balance_test(test_data)

    # Test with different window sizes
    @window_sizes.each do |size|
      puts "\n#{YELLOW}Testing Sliding Window Strategy with Window Size #{size}#{RESET}"
      run_balance_test(test_data, strategy: :sliding_window, window_size: size)
    end

    # Test with custom type order
    puts "\n#{YELLOW}Testing with Custom Type Order#{RESET}"
    run_balance_test(
      test_data,
      strategy: :sliding_window,
      types: %w[type_c type_b type_a],
      window_size: 25
    )
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

  def run_balance_test(items, strategy_options = {})
    puts "\nRunning balance test..."
    puts "Strategy options: #{strategy_options.inspect}" unless strategy_options.empty?

    # Balance the items
    balanced_items = TypeBalancer.balance(items, type_field: :type, **strategy_options)

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
      target_percentage = (@type_distribution[type].to_f / @total_records * 100).round(1)
      diff = (percentage - target_percentage).abs.round(1)
      color = if diff <= 1.0
                GREEN
              elsif diff <= 2.0
                YELLOW
              else
                RED
              end
      puts "#{color}#{type}: #{count} (#{percentage}%) - Target: #{target_percentage}% (Diff: #{diff}%)#{RESET}"
    end

    # Analyze type transitions
    analyze_type_transitions(balanced_items)
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

  def analyze_type_transitions(items)
    puts "\nType Transition Analysis:"
    transitions = Hash.new { |h, k| h[k] = Hash.new(0) }
    total_transitions = 0

    items.each_cons(2) do |a, b|
      transitions[a[:type]][b[:type]] += 1
      total_transitions += 1
    end

    transitions.each do |from_type, to_types|
      puts "\nTransitions from #{from_type}:"
      to_types.each do |to_type, count|
        percentage = (count.to_f / total_transitions * 100).round(1)
        puts "  to #{to_type}: #{count} (#{percentage}%)"
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  test = LargeScaleBalanceTest.new
  test.run
end
