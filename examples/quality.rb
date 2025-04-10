# frozen_string_literal: true

# CAUTION: This script serves multiple critical purposes:
# 1. API Stability Check: This script exercises all public interfaces of the gem.
#    Any changes that break this script likely represent breaking changes that
#    would affect users. Changes should be carefully considered and reviewed.
# 2. Integration Test: Ensures all components work together as expected.
# 3. Usage Example: Demonstrates recommended usage patterns for users.
# 4. CI Verification: Runs in CI to catch potential breaking changes.
#
# When modifying this script:
# - Ensure all public interfaces are exercised
# - Maintain backward compatibility
# - Update examples to reflect best practices
# - Add new test cases for new features

require 'type_balancer'

class QualityChecker
  Item = Struct.new(:content_type)

  def initialize
    @issues = []
    @examples_run = 0
    @examples_passed = 0
  end

  def run
    check_basic_distribution
    check_available_items
    check_edge_cases
    check_real_world_feed
    check_balancer_api
    check_type_extraction
    check_error_handling

    print_summary
    exit(@issues.empty? ? 0 : 1)
  end

  private

  def record_issue(message)
    @issues << message
  end

  def check_basic_distribution
    @examples_run += 1
    puts "\nBasic Distribution Example:"
    positions = TypeBalancer.calculate_positions(total_count: 10, ratio: 0.3)

    if positions == [0, 5, 9]
      @examples_passed += 1
    else
      record_issue("Basic distribution positions #{positions.inspect} don't match expected [0, 5, 9]")
    end

    spacing = positions&.each_cons(2)&.map { |a, b| b - a }
    puts "Positions for 3 items across 10 slots: #{positions.inspect}"
    puts "Spacing between positions: #{spacing.inspect}"

    return unless spacing != [5, 4]

    record_issue("Basic distribution spacing #{spacing.inspect} isn't optimal [5, 4]")
  end

  def check_available_items
    @examples_run += 1
    puts "\nAvailable Items Example:"
    positions = TypeBalancer.calculate_positions(
      total_count: 10,
      ratio: 0.5,
      available_items: [0, 1, 2]
    )

    if positions == [0, 1, 2]
      @examples_passed += 1
    else
      record_issue("Available items test returned #{positions.inspect} instead of expected [0, 1, 2]")
    end

    puts "Positions when only 3 slots available: #{positions.inspect}"
  end

  def check_edge_cases
    puts "\nEdge Cases:"

    # Single item
    @examples_run += 1
    single = TypeBalancer.calculate_positions(total_count: 1, ratio: 1.0)
    puts "Single item: #{single.inspect}"
    if single == [0]
      @examples_passed += 1
    else
      record_issue("Single item case returned #{single.inspect} instead of [0]")
    end

    # No items
    @examples_run += 1
    none = TypeBalancer.calculate_positions(total_count: 100, ratio: 0.0)
    puts "No items needed: #{none.inspect}"
    if none == []
      @examples_passed += 1
    else
      record_issue("Zero ratio case returned #{none.inspect} instead of []")
    end

    # All items
    @examples_run += 1
    all = TypeBalancer.calculate_positions(total_count: 5, ratio: 1.0)
    puts "All items needed: #{all.inspect}"
    if all == [0, 1, 2, 3, 4]
      @examples_passed += 1
    else
      record_issue("Full ratio case returned #{all.inspect} instead of [0, 1, 2, 3, 4]")
    end
  end

  def check_real_world_feed
    @examples_run += 1
    puts "\nReal World Example - Content Feed:"
    feed_size = 20

    # Track allocated positions
    allocated_positions = []
    content_positions = {}

    # Calculate positions for each type
    content_positions[:video] = TypeBalancer.calculate_positions(
      total_count: feed_size,
      ratio: 0.3,
      available_items: (0..7).to_a - allocated_positions
    )
    allocated_positions += content_positions[:video]

    content_positions[:image] = TypeBalancer.calculate_positions(
      total_count: feed_size,
      ratio: 0.4,
      available_items: (0..14).to_a - allocated_positions
    )
    allocated_positions += content_positions[:image]

    content_positions[:article] = TypeBalancer.calculate_positions(
      total_count: feed_size,
      ratio: 0.3,
      available_items: (0..19).to_a - allocated_positions
    )

    puts "\nContent Type Positions:"
    content_positions.each do |type, pos|
      puts "#{type}: #{pos.inspect}"
    end

    # Check for overlaps
    all_positions = content_positions.values.compact.flatten
    if all_positions == all_positions.uniq
      puts "\nSuccess: No overlapping positions!"
      @examples_passed += 1
    else
      overlaps = all_positions.group_by { |e| e }.select { |_, v| v.size > 1 }.keys
      record_issue("Found overlapping positions at indices: #{overlaps.inspect}")
      puts "\nWarning: Some positions overlap!"
    end

    # Verify distribution
    puts "\nDistribution Stats:"
    expected_counts = { video: 6, image: 8, article: 6 }
    content_positions.each do |type, positions|
      count = positions&.length || 0
      percentage = (count.to_f / feed_size * 100).round(1)
      puts "#{type}: #{count} items (#{percentage}% of feed)"

      if count != expected_counts[type]
        record_issue("#{type} count #{count} doesn't match expected #{expected_counts[type]}")
      end
    end
  end

  def check_balancer_api
    @examples_run += 1
    puts "\nBalancer API Example:"
    
    # Create test items
    items = [
      { type: 'video', id: 1 },
      { type: 'video', id: 2 },
      { type: 'image', id: 3 },
      { type: 'image', id: 4 },
      { type: 'article', id: 5 }
    ]

    # Test basic balancing
    batches = TypeBalancer.balance(
      items,
      types: %w[video image article],
      batch_size: 3
    )

    # Verify batch size
    if batches.all? { |batch| batch.size <= 3 }
      @examples_passed += 1
    else
      record_issue("Some batches exceed the specified batch size of 3")
    end

    puts "Balanced batches:"
    batches.each_with_index do |batch, i|
      puts "Batch #{i + 1}: #{batch.map { |item| "#{item[:type]}(#{item[:id]})" }.join(', ')}"
    end

    # Test with custom type order
    ordered_batches = TypeBalancer.balance(
      items,
      types: %w[video image article],
      type_order: %w[article image video],
      batch_size: 3
    )

    # Verify type order in first batch
    first_batch = ordered_batches.first
    if first_batch && first_batch.first[:type] == 'article'
      @examples_passed += 1
    else
      record_issue("Custom type order not respected in first batch")
    end

    puts "\nBalanced batches with custom order:"
    ordered_batches.each_with_index do |batch, i|
      puts "Batch #{i + 1}: #{batch.map { |item| "#{item[:type]}(#{item[:id]})" }.join(', ')}"
    end
  end

  def check_type_extraction
    @examples_run += 1
    puts "\nType Extraction Example:"

    # Test with hash items
    hash_items = [
      { type: 'video' },
      { type: 'image' },
      { 'type' => 'article' }  # String key
    ]

    types = TypeBalancer.extract_types(hash_items, :type)
    if types.sort == %w[article image video]
      @examples_passed += 1
    else
      record_issue("Type extraction failed for hash items: #{types.inspect}")
    end

    puts "Extracted types from hash items: #{types.inspect}"

    # Test with custom objects
    object_items = [
      Item.new('video'),
      Item.new('image'),
      Item.new('article')
    ]

    object_types = TypeBalancer.extract_types(object_items, :content_type)
    if object_types.sort == %w[article image video]
      @examples_passed += 1
    else
      record_issue("Type extraction failed for object items: #{object_types.inspect}")
    end

    puts "Extracted types from object items: #{object_types.inspect}"
  end

  def check_error_handling
    @examples_run += 1
    puts "\nError Handling Example:"

    # Test empty collection
    begin
      TypeBalancer.balance([], types: ['video'])
      record_issue("Failed to raise error for empty collection")
    rescue TypeBalancer::EmptyCollectionError
      @examples_passed += 1
      puts "✓ Correctly handled empty collection"
    end

    # Test empty types
    begin
      TypeBalancer.balance([{ type: 'video' }], types: [])
      record_issue("Failed to raise error for empty types")
    rescue ArgumentError
      @examples_passed += 1
      puts "✓ Correctly handled empty types"
    end

    # Test invalid type field
    begin
      TypeBalancer.balance([{ wrong_field: 'video' }], types: ['video'])
      record_issue("Failed to raise error for invalid type field")
    rescue TypeBalancer::Error
      @examples_passed += 1
      puts "✓ Correctly handled invalid type field"
    end

    # Test invalid batch size
    begin
      TypeBalancer.balance([{ type: 'video' }], types: ['video'], batch_size: 0)
      record_issue("Failed to raise error for invalid batch size")
    rescue ArgumentError
      @examples_passed += 1
      puts "✓ Correctly handled invalid batch size"
    end
  end

  def print_summary
    puts "\n#{'-' * 50}"
    puts 'Quality Check Summary:'
    puts "Examples Run: #{@examples_run}"
    puts "Examples Passed: #{@examples_passed}"

    if @issues.empty?
      puts "\nAll quality checks passed! ✓"
    else
      puts "\nQuality check failed with #{@issues.size} issues:"
      @issues.each_with_index do |issue, index|
        puts "#{index + 1}. #{issue}"
      end
    end
    puts "#{'-' * 50}"
  end
end

QualityChecker.new.run
