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
    @failures = []
    @tests_run = 0
    @tests_passed = 0
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

    print_summary
    @failures.empty?
  end

  private

  def record_failure(message)
    @failures << message
  end

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
    @tests_run += 1
    puts "\nRunning balance test..."
    puts "Strategy options: #{strategy_options.inspect}" unless strategy_options.empty?

    # Balance the items
    balanced_items = TypeBalancer.balance(items, type_field: :type, **strategy_options)

    # Track if this test passes
    test_passed = true

    # Analyze distribution in chunks
    chunk_sizes = [10, 25, 50, 100]
    chunk_sizes.each do |size|
      chunk_result = analyze_chunk(balanced_items, size)
      test_passed = false unless chunk_result
    end

    # Analyze full distribution
    distribution_result = analyze_full_distribution(balanced_items)
    test_passed = false unless distribution_result

    # Analyze type transitions
    transition_result = analyze_type_transitions(balanced_items)
    test_passed = false unless transition_result

    @tests_passed += 1 if test_passed
  end

  def analyze_chunk(items, size)
    puts "\nAnalyzing first #{size} items:"
    chunk = items.first(size)
    distribution = chunk.map { |item| item[:type] }.tally
    chunk_passed = true

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

      if diff.abs > 2
        record_failure("Chunk size #{size}: #{type} distribution off by #{diff} (expected ~#{ideal_count.round(1)}, got #{actual_count})")
        chunk_passed = false
      end
    end

    chunk_passed
  end

  def analyze_full_distribution(balanced_items)
    puts "\nFull Distribution Analysis:"
    distribution = balanced_items.map { |item| item[:type] }.tally
    distribution_passed = true

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

      if diff > 2.0
        record_failure("Full distribution: #{type} off by #{diff}% (expected #{target_percentage}%, got #{percentage}%)")
        distribution_passed = false
      end
    end

    distribution_passed
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
    transition_passed = true

    items.each_cons(2) do |a, b|
      transitions[a[:type]][b[:type]] += 1
      total_transitions += 1
    end

    transitions.each do |from_type, to_types|
      puts "\nTransitions from #{from_type}:"
      same_type_transitions = to_types[from_type] || 0
      same_type_percentage = (same_type_transitions.to_f / total_transitions * 100).round(1)

      to_types.each do |to_type, count|
        percentage = (count.to_f / total_transitions * 100).round(1)
        puts "  to #{to_type}: #{count} (#{percentage}%)"
      end

      if same_type_percentage > 30
        record_failure("Too many consecutive #{from_type} items (#{same_type_percentage}% of transitions)")
        transition_passed = false
      end
    end

    transition_passed
  end

  def print_summary
    puts "\n#{'-' * 50}"
    puts 'Large Scale Balance Test Summary:'
    puts "Tests Run: #{@tests_run}"
    puts "Tests Passed: #{@tests_passed}"

    if @failures.empty?
      puts "\n#{GREEN}All large scale balance tests passed! ✓#{RESET}"
    else
      puts "\n#{RED}Large scale balance test failed with #{@failures.size} issues:#{RESET}"
      @failures.each_with_index do |failure, index|
        puts "#{RED}#{index + 1}. #{failure}#{RESET}"
      end
    end
    puts "#{'-' * 50}"
  end
end

if __FILE__ == $PROGRAM_NAME
  test = LargeScaleBalanceTest.new
  exit(test.run ? 0 : 1)
end
