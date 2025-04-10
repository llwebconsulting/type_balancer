# frozen_string_literal: true

require 'test_helper'

# This file serves as both a test and an example of how to use TypeBalancer
# You can run it directly in IRB to see how the balancing works
class QualityTest < Minitest::Test
  def test_basic_distribution
    # Example: Distribute 3 videos across 10 items
    positions = TypeBalancer.calculate_positions(total_count: 10, ratio: 0.3)

    # Should return roughly evenly spaced positions
    assert_equal 3, positions.length
    assert_equal positions, positions.sort # Positions should be in order
    assert(positions.all? { |pos| pos.between?(1, 10) })

    # Positions should be roughly evenly spaced
    positions.each_cons(2) do |a, b|
      spacing = b - a
      assert_in_delta 2.5, spacing, 1.5, 'Spacing between positions should be roughly even'
    end
  end

  def test_respects_available_items
    # Example: Try to distribute 5 videos but only 3 are available
    positions = TypeBalancer.calculate_positions(
      total_count: 10,
      ratio: 0.5,
      available_items: 3
    )

    assert_equal 3, positions.length
    assert(positions.all? { |pos| pos <= 3 })
  end

  def test_handles_edge_cases
    # Single item
    positions = TypeBalancer.calculate_positions(total_count: 1, ratio: 1.0)
    assert_equal [1], positions

    # No items needed
    positions = TypeBalancer.calculate_positions(total_count: 100, ratio: 0.0)
    assert_empty positions

    # All items needed
    positions = TypeBalancer.calculate_positions(total_count: 5, ratio: 1.0)
    assert_equal (1..5).to_a, positions
  end

  def test_invalid_inputs
    assert_raises(ArgumentError) { TypeBalancer.calculate_positions(total_count: 0, ratio: 0.5) }
    assert_raises(ArgumentError) { TypeBalancer.calculate_positions(total_count: -1, ratio: 0.5) }
    assert_raises(ArgumentError) { TypeBalancer.calculate_positions(total_count: 100, ratio: -0.1) }
    assert_raises(ArgumentError) { TypeBalancer.calculate_positions(total_count: 100, ratio: 1.1) }
  end

  def test_real_world_example
    feed_size = 20
    positions = calculate_content_type_positions(feed_size)
    verify_position_counts(positions, feed_size)
    verify_no_overlaps(positions)
    verify_position_bounds(positions, feed_size)
  end

  private

  def calculate_content_type_positions(feed_size)
    {
      video: TypeBalancer.calculate_positions(
        total_count: feed_size,
        ratio: 0.3, # 30% videos
        available_items: 8 # Only 8 videos available
      ),
      image: TypeBalancer.calculate_positions(
        total_count: feed_size,
        ratio: 0.4, # 40% images
        available_items: 15 # 15 images available
      ),
      article: TypeBalancer.calculate_positions(
        total_count: feed_size,
        ratio: 0.3 # 30% articles
      )
    }
  end

  def verify_position_counts(positions, _feed_size)
    assert_equal 6, positions[:video].length   # 30% of 20 = 6, but limited by available_items
    assert_equal 8, positions[:image].length   # 40% of 20 = 8
    assert_equal 6, positions[:article].length # 30% of 20 = 6
  end

  def verify_no_overlaps(positions)
    all_positions = positions.values.flatten
    assert_equal all_positions, all_positions.uniq, 'Content types should not overlap'
  end

  def verify_position_bounds(positions, feed_size)
    all_positions = positions.values.flatten
    assert(all_positions.all? { |pos| pos.between?(1, feed_size) })
  end
end
