# frozen_string_literal: true

module TypeBalancer
  # Calculates ratios and positions for balanced distribution of items
  module RatioCalculator
    module_function

    # Calculate positions for each type based on ratios and batch size
    #
    # @param ratios [Hash<String, Float>] Ratios for each type
    # @param batch_size [Integer] Size of each batch
    # @return [Hash<String, Array<Integer>>] Positions for each type in batches
    def calculate_positions(ratios, batch_size)
      # Initialize variables
      positions = {}
      total_positions = 0

      # First pass: Calculate minimum positions for each type
      ratios.each do |type, ratio|
        min_positions = (batch_size * ratio).ceil
        positions[type] = min_positions
        total_positions += min_positions
      end

      # Second pass: Adjust if we have too many positions
      reduce_positions(positions, batch_size) if total_positions > batch_size

      # Third pass: Fill remaining positions if we have too few
      fill_remaining_positions(positions, batch_size - total_positions, ratios) if total_positions < batch_size

      positions
    end

    private

    def reduce_positions(positions, target_size)
      while positions.values.sum > target_size
        # Find type with most positions relative to its ratio
        type_to_reduce = positions.max_by { |_, count| count }[0]
        positions[type_to_reduce] -= 1
      end
    end

    def fill_remaining_positions(positions, remaining_count, ratios)
      remaining_count.times do
        # Add position to type with lowest current/ratio ratio
        type_to_increase = find_type_needing_position(positions, ratios)
        positions[type_to_increase] += 1
      end
    end

    def find_type_needing_position(positions, ratios)
      ratios.min_by { |type, ratio| positions[type].to_f / (ratio * positions.values.sum) }[0]
    end

    class << self
      def calculate_ratios(types, items_by_type)
        return { types.first => 1.0 } if types.size == 1

        # Create a hash of type counts
        type_counts = types.to_h { |type| [type, items_by_type.fetch(type, []).size] }
        total_count = type_counts.values.sum.to_f

        # Calculate initial ratios
        ratios = calculate_initial_ratios(type_counts, total_count)

        # Normalize ratios
        normalize_ratios(ratios)
      end

      private

      def calculate_initial_ratios(type_counts, total_count)
        type_counts.transform_values { |count| count / total_count }
      end

      def normalize_ratios(ratios)
        sum = ratios.values.sum
        ratios.transform_values { |ratio| ratio / sum }
      end
    end
  end
end
