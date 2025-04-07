# frozen_string_literal: true

require 'type_balancer'
require 'benchmark'

# Test data generator
class TestDataGenerator
  def self.generate_items(count = 100)
    types = %w[video image article]
    count.times.map do |i|
      type = types[i % types.size]
      { type: type, id: i, title: "#{type.capitalize} #{i}" }
    end
  end

  def self.generate_custom_items(count = 100)
    types = %w[video image article]
    count.times.map do |i|
      type = types[i % types.size]
      TestItem.new(type, i, "#{type.capitalize} #{i}")
    end
  end
end

# Custom test item class
class TestItem
  attr_reader :type, :id, :title

  def initialize(type, id, title)
    @type = type
    @id = id
    @title = title
  end

  def to_s
    "#{type}:#{id}"
  end
end

# Test runner class
class QualityTest
  def initialize
    @total_tests = 0
    @passed_tests = 0
    @failed_tests = []
  end

  def run
    puts 'Running TypeBalancer Quality Tests'
    puts '================================='
    puts

    test_c_extension_default
    test_ruby_implementation
    test_custom_objects
    test_performance_comparison
    test_edge_cases
    test_type_ordering
    test_large_dataset

    report_results
  end

  private

  def assert(condition, message)
    @total_tests += 1
    if condition
      @passed_tests += 1
      print '.'
    else
      @failed_tests << message
      print 'F'
    end
  end

  def test_c_extension_default
    puts "\nTesting C Extension (Default):"

    # Ensure C extensions are enabled
    TypeBalancer.configure { |config| config.use_c_extensions = true }

    items = TestDataGenerator.generate_items(10)
    balanced = TypeBalancer.balance(items)

    assert(
      balanced.size == items.size,
      "C Extension: Expected balanced size #{items.size}, got #{balanced.size}"
    )

    # Test type distribution
    types = balanced.map { |item| item[:type] }
    assert(
      types.uniq.size == 3,
      "C Extension: Expected 3 unique types, got #{types.uniq.size}"
    )

    # Test that items are distributed
    video_positions = types.each_index.select { |i| types[i] == 'video' }
    assert(
      !video_positions.empty?,
      'C Extension: No video items found in balanced result'
    )

    # Test spacing between same types
    max_consecutive = types.chunk { |t| t }.map(&:last).map(&:size).max
    assert(
      max_consecutive <= 2,
      "C Extension: Too many consecutive items of same type (#{max_consecutive})"
    )
  end

  def test_ruby_implementation
    puts "\nTesting Ruby Implementation:"

    # Switch to Ruby implementation
    TypeBalancer.configure { |config| config.use_c_extensions = false }

    items = TestDataGenerator.generate_items(10)
    balanced = TypeBalancer.balance(items)

    assert(
      balanced.size == items.size,
      "Ruby Implementation: Expected balanced size #{items.size}, got #{balanced.size}"
    )

    # Test type distribution
    types = balanced.map { |item| item[:type] }
    assert(
      types.uniq.size == 3,
      "Ruby Implementation: Expected 3 unique types, got #{types.uniq.size}"
    )

    # Verify we're actually using Ruby implementation
    assert(
      !TypeBalancer.use_c_extensions?,
      'Ruby Implementation: Should be using Ruby implementation'
    )
  end

  def test_custom_objects
    puts "\nTesting Custom Objects:"

    items = TestDataGenerator.generate_custom_items(10)

    # Test with both implementations
    [true, false].each do |use_c|
      TypeBalancer.configure { |config| config.use_c_extensions = use_c }
      implementation = use_c ? 'C Extension' : 'Ruby'

      balanced = TypeBalancer.balance(items, type_field: :type)

      assert(
        balanced.size == items.size,
        "#{implementation} Custom Objects: Expected size #{items.size}, got #{balanced.size}"
      )

      assert(
        balanced.all? { |item| item.is_a?(TestItem) },
        "#{implementation} Custom Objects: Not all items are TestItem instances"
      )
    end
  end

  def test_performance_comparison
    puts "\nTesting Performance:"

    items = TestDataGenerator.generate_items(1000)

    c_time = Benchmark.realtime do
      TypeBalancer.configure { |config| config.use_c_extensions = true }
      TypeBalancer.balance(items)
    end

    ruby_time = Benchmark.realtime do
      TypeBalancer.configure { |config| config.use_c_extensions = false }
      TypeBalancer.balance(items)
    end

    puts "\nC Extension: #{c_time.round(4)}s"
    puts "Ruby: #{ruby_time.round(4)}s"

    assert(
      c_time < ruby_time,
      "Performance: C Extension (#{c_time.round(4)}s) should be faster than Ruby (#{ruby_time.round(4)}s)"
    )
  end

  def test_edge_cases
    puts "\nTesting Edge Cases:"

    [true, false].each do |use_c|
      TypeBalancer.configure { |config| config.use_c_extensions = use_c }
      implementation = use_c ? 'C Extension' : 'Ruby'

      # Empty collection
      assert(
        TypeBalancer.balance([]).empty?,
        "#{implementation}: Empty collection should return empty array"
      )

      # Single item
      single_item = [{ type: 'video', id: 1 }]
      assert(
        TypeBalancer.balance(single_item).size == 1,
        "#{implementation}: Single item should return array of size 1"
      )

      # All same type
      same_type = 3.times.map { |i| { type: 'video', id: i } }
      balanced = TypeBalancer.balance(same_type)
      assert(
        balanced.map { |i| i[:type] }.uniq.size == 1,
        "#{implementation}: All items should be of same type"
      )
    end
  end

  def test_type_ordering
    puts "\nTesting Type Ordering:"

    items = TestDataGenerator.generate_items(9) # 3 of each type
    type_order = %w[article image video]

    [true, false].each do |use_c|
      TypeBalancer.configure { |config| config.use_c_extensions = use_c }
      implementation = use_c ? 'C Extension' : 'Ruby'

      balanced = TypeBalancer.balance(items, type_order: type_order)
      first_type = balanced.first[:type]

      assert(
        first_type == type_order.first,
        "#{implementation}: Expected first type to be #{type_order.first}, got #{first_type}"
      )
    end
  end

  def test_large_dataset
    puts "\nTesting Large Dataset:"

    items = TestDataGenerator.generate_items(10_000)

    [true, false].each do |use_c|
      TypeBalancer.configure { |config| config.use_c_extensions = use_c }
      implementation = use_c ? 'C Extension' : 'Ruby'

      balanced = nil
      time = Benchmark.realtime do
        balanced = TypeBalancer.balance(items)
      end

      assert(
        balanced.size == items.size,
        "#{implementation}: Large dataset size mismatch"
      )

      puts "\n#{implementation} large dataset time: #{time.round(4)}s"
    end
  end

  def report_results
    puts "\n\nTest Results:"
    puts '============='
    puts "Total Tests: #{@total_tests}"
    puts "Passed: #{@passed_tests}"
    puts "Failed: #{@failed_tests.size}"

    if @failed_tests.any?
      puts "\nFailed Tests:"
      @failed_tests.each_with_index do |message, index|
        puts "#{index + 1}. #{message}"
      end
    end

    exit(@failed_tests.empty? ? 0 : 1)
  end
end

# Run the tests
QualityTest.new.run
