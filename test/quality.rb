# frozen_string_literal: true

require 'test_helper'

class QualityTest < Minitest::Test
  def setup
    # Test both implementations
    @implementations = %i[ruby c]
  end

  def test_positions_are_evenly_distributed
    test_cases = [
      { total_count: 100, ratio: 0.1 },
      { total_count: 1000, ratio: 0.2 },
      { total_count: 10_000, ratio: 0.3 },
      { total_count: 100_000, ratio: 0.4 }
    ]

    test_cases.each do |params|
      # Get results from both implementations
      results = @implementations.map do |impl|
        TypeBalancer.implementation = impl
        TypeBalancer.calculate_positions(**params)
      end

      # Verify both implementations produce identical results
      assert_equal results[0], results[1],
                   "Ruby and C implementations produced different results for #{params}"

      positions = results[0] # Use either result since they're identical

      # Test position distribution
      positions.each_cons(2) do |a, b|
        spacing = b - a
        expected_spacing = params[:total_count] / (positions.length + 1)

        # Allow for some rounding variation
        assert_in_delta expected_spacing, spacing, expected_spacing * 0.5,
                        "Uneven spacing detected between positions #{a} and #{b}"
      end
    end
  end

  def test_positions_respect_available_items
    test_cases = [
      { total_count: 100, ratio: 0.3, available_items: 20 },
      { total_count: 1000, ratio: 0.2, available_items: 150 },
      { total_count: 10_000, ratio: 0.1, available_items: 800 }
    ]

    test_cases.each do |params|
      # Get results from both implementations
      results = @implementations.map do |impl|
        TypeBalancer.implementation = impl
        TypeBalancer.calculate_positions(**params)
      end

      # Verify both implementations produce identical results
      assert_equal results[0], results[1],
                   "Ruby and C implementations produced different results for #{params}"

      positions = results[0] # Use either result since they're identical

      # Verify positions don't exceed available_items
      assert positions.all? { |pos| pos <= params[:available_items] },
             'Positions exceed available_items limit'

      # Verify we don't return more positions than available
      target_count = (params[:total_count] * params[:ratio]).to_i
      expected_count = [target_count, params[:available_items]].min
      assert positions.length <= expected_count,
             'Too many positions returned'
    end
  end

  def test_edge_cases
    edge_cases = [
      { total_count: 1, ratio: 0.1 },
      { total_count: 100, ratio: 1.0 },
      { total_count: 1000, ratio: 0.001 },
      { total_count: 10_000, ratio: 0.9999 }
    ]

    edge_cases.each do |params|
      # Get results from both implementations
      results = @implementations.map do |impl|
        TypeBalancer.implementation = impl
        TypeBalancer.calculate_positions(**params)
      end

      # Verify both implementations produce identical results
      assert_equal results[0], results[1],
                   "Ruby and C implementations produced different results for #{params}"

      positions = results[0] # Use either result since they're identical

      # Basic sanity checks
      assert positions.length <= params[:total_count],
             'More positions than total_count'
      assert positions.uniq.length == positions.length,
             'Duplicate positions found'
      assert positions.all? { |pos| pos.between?(1, params[:total_count]) },
             'Positions outside valid range'
    end
  end

  def test_invalid_inputs
    invalid_cases = [
      { total_count: 0, ratio: 0.5 },
      { total_count: -100, ratio: 0.5 },
      { total_count: 100, ratio: 0 },
      { total_count: 100, ratio: -0.5 },
      { total_count: 100, ratio: 1.1 }
    ]

    invalid_cases.each do |params|
      @implementations.each do |impl|
        TypeBalancer.implementation = impl
        assert_raises(ArgumentError, "#{impl} implementation should raise ArgumentError for #{params}") do
          TypeBalancer.calculate_positions(**params)
        end
      end
    end
  end
end
