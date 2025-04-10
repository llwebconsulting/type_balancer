# frozen_string_literal: true

require 'type_balancer'

class QualityChecker
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
