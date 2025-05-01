#!/usr/bin/env ruby
# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity

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

    # Get window size (default is 10)
    window_size = strategy_options[:window_size] || 10

    # Track remaining items for each type
    remaining_items = @type_distribution.dup

    # Analyze windows
    balanced_items.each_slice(window_size).with_index do |window, index|
      window_result = analyze_window(window, index + 1, remaining_items)
      test_passed = false unless window_result

      # Update remaining items
      window.each do |item|
        remaining_items[item[:type]] -= 1
      end
    end

    # Analyze full distribution
    distribution_result = analyze_full_distribution(balanced_items)
    test_passed = false unless distribution_result

    # Analyze type transitions
    transition_result = analyze_type_transitions(balanced_items)
    test_passed = false unless transition_result

    @tests_passed += 1 if test_passed
  end

  def analyze_window(items, window_number, remaining_items)
    puts "\nAnalyzing window #{window_number} (#{items.size} items):"
    distribution = items.map { |item| item[:type] }.tally
    window_passed = true

    distribution.each do |type, count|
      percentage = (count.to_f / items.size * 100).round(1)
      puts "#{type}: #{count} (#{percentage}%)"
    end

    # Calculate how many items we have left to work with
    total_remaining = remaining_items.values.sum
    remaining_items.transform_values { |count| count.to_f / total_remaining }

    # Only enforce strict distribution when we have enough items of each type
    has_enough_items = remaining_items.values.all? { |count| count >= items.size / 3 }

    if has_enough_items
      # When we have enough items, ensure each type that has items left appears at least once
      remaining_items.each do |type, count|
        next if count <= 0

        unless distribution.key?(type)
          record_failure("Window #{window_number}: #{type} does not appear but has #{count} items remaining")
          window_passed = false
        end
      end

      # Prevent any type from completely dominating a window when we have enough items
      max_allowed = (items.size * 0.7).ceil # Allow up to 70% when we have enough items
      distribution.each do |type, count|
        next unless count > max_allowed

        message = "Window #{window_number}: #{type} appears #{count} times (#{percentage}%), "
        message += "exceeding maximum allowed #{max_allowed} when sufficient items remain"
        record_failure(message)
        window_passed = false
      end
    else
      # When running low on items, just verify we're using available items efficiently
      distribution.each do |type, count|
        max_possible = [remaining_items[type], items.size].min
        next unless count > max_possible

        message = "Window #{window_number}: #{type} appears #{count} times but only had #{max_possible} items available"
        record_failure(message)
        window_passed = false
      end
    end

    window_passed
  end

  def analyze_full_distribution(balanced_items)
    puts "\nFull Distribution Analysis:"
    distribution = balanced_items.map { |item| item[:type] }.tally
    distribution_passed = true

    distribution.each do |type, count|
      percentage = (count.to_f / balanced_items.length * 100).round(1)
      target_percentage = (@type_distribution[type].to_f / @total_records * 100).round(1)
      diff = (percentage - target_percentage).abs.round(1)
      color = if diff <= 0.1
                GREEN
              elsif diff <= 0.5
                YELLOW
              else
                RED
              end
      puts "#{color}#{type}: #{count} (#{percentage}%) - Target: #{target_percentage}% (Diff: #{diff}%)#{RESET}"

      # Full distribution should be very close to target
      next unless diff > 0.5

      message = "Full distribution: #{type} off by #{diff}% "
      message += "(expected #{target_percentage}%, got #{percentage}%)"
      record_failure(message)
      distribution_passed = false
    end

    distribution_passed
  end

  def analyze_type_transitions(items)
    puts "\nType Transition Analysis:"
    transitions = Hash.new { |h, k| h[k] = Hash.new(0) }
    total_transitions = 0
    transition_passed = true

    # Track consecutive occurrences
    current_type = nil
    consecutive_count = 0
    remaining_items = @type_distribution.dup

    items.each do |item|
      # Update remaining items
      remaining_items[item[:type]] -= 1
      total_remaining = remaining_items.values.sum
      available_types = remaining_items.count { |_, count| count.positive? }

      if item[:type] == current_type
        consecutive_count += 1
        # Allow longer runs when we're running out of items
        max_consecutive = if available_types >= 3 && total_remaining >= 100
                            5 # Strict when we have lots of items and all types
                          elsif available_types >= 2 && total_remaining >= 50
                            8  # More lenient as we start running out
                          elsif available_types >= 2 && total_remaining >= 20
                            12 # Even more lenient with two types
                          else
                            Float::INFINITY # No limit when almost out or only one type left
                          end

        if consecutive_count > max_consecutive
          message = "Found #{consecutive_count} consecutive #{current_type} items "
          message += "when #{total_remaining} total items remained (#{available_types} types available)"
          record_failure(message)
          transition_passed = false
          break # Stop checking transitions once we find a violation
        end
      else
        consecutive_count = 1
        current_type = item[:type]
      end
    end

    # Analyze transitions for information only
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

    transition_passed
  end

  def print_summary
    puts "\n#{'-' * 50}"
    if @failures.empty?
      puts "#{GREEN}All tests passed!#{RESET}"
    else
      puts "#{RED}#{@failures.size} test failures:#{RESET}"
      @failures.each_with_index do |failure, index|
        puts "#{index + 1}. #{failure}"
      end
    end
    puts "Tests run: #{@tests_run}"
    puts "Tests passed: #{@tests_passed}"
    puts('-' * 50)
  end
end

if __FILE__ == $PROGRAM_NAME
  test = LargeScaleBalanceTest.new
  exit(test.run ? 0 : 1)
end

# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/PerceivedComplexity
