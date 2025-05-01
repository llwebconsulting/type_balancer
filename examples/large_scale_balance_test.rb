#!/usr/bin/env ruby
# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize

require_relative '../lib/type_balancer'
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

  def run_balance_test(test_data, **options)
    @tests_run += 1
    puts "\nRunning balance test..."

    begin
      result = TypeBalancer.balance(test_data, type_field: :type, **options)
      analyze_result(result, options)
      @tests_passed += 1
    rescue StandardError => e
      record_failure("Balance test failed: #{e.message}")
      puts "#{RED}Balance test failed: #{e.message}#{RESET}"
    end
  end

  def analyze_result(result, options)
    window_size = options[:window_size] || 10
    puts "\nAnalyzing windows of size #{window_size}:"

    result.each_slice(window_size).with_index(1) do |window, index|
      analyze_window(window, index)
    end

    analyze_overall_distribution(result)
  end

  def analyze_window(window, window_number)
    puts "\nAnalyzing window #{window_number} (#{window.size} items):"
    type_counts = window.group_by { |item| item[:type] }.transform_values(&:size)
    total_in_window = window.size.to_f

    type_counts.each do |type, count|
      percentage = (count / total_in_window * 100).round(1)
      target_percentage = (@type_distribution[type].to_f / @total_records * 100).round(1)
      diff = (percentage - target_percentage).abs.round(1)

      message = "#{type}: #{count} (#{percentage}%), "
      message += if diff <= 15
                   "#{GREEN}acceptable deviation#{RESET}"
                 else
                   "#{RED}high deviation#{RESET}"
                 end

      puts message
    end
  end

  def analyze_overall_distribution(result)
    puts "\nOverall Distribution:"
    type_counts = result.group_by { |item| item[:type] }.transform_values(&:size)
    total = result.size.to_f

    type_counts.each do |type, count|
      percentage = (count / total * 100).round(1)
      target_percentage = (@type_distribution[type].to_f / @total_records * 100).round(1)
      diff = (percentage - target_percentage).abs.round(1)

      message = "#{type}: #{count} (#{percentage}% vs target #{target_percentage}%), "
      message += if diff <= 5
                   "#{GREEN}good distribution#{RESET}"
                 else
                   "#{RED}distribution needs improvement#{RESET}"
                 end

      puts message
    end
  end

  def print_summary
    puts "\n#{YELLOW}Test Summary:#{RESET}"
    puts "Tests Run: #{@tests_run}"
    puts "Tests Passed: #{@tests_passed}"
    puts "Failures: #{@failures.size}"

    if @failures.any?
      puts "\n#{RED}Failures:#{RESET}"
      @failures.each { |failure| puts "- #{failure}" }
    else
      puts "\n#{GREEN}All tests passed!#{RESET}"
    end
  end
end

# Run the test
test = LargeScaleBalanceTest.new
exit(test.run ? 0 : 1)

# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/AbcSize
