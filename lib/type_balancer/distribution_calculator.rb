# frozen_string_literal: true

module TypeBalancer
  # Calculates the optimal distribution of items by type in a sequence.
  # For each type, it determines the ideal positions where items of that type
  # should be placed to achieve a balanced distribution.
  class DistributionCalculator
    def initialize(target_ratio = 0.2)
      @target_ratio = target_ratio
    end

    def calculate_target_positions(total_count, available_items_count)
      target_count = calculate_target_count(total_count, available_items_count)
      return [] if target_count.zero?

      calculate_distributed_positions(total_count, target_count)
    end

    private

    def calculate_target_count(total_count, available_items_count)
      target_count = (total_count * @target_ratio).ceil
      [target_count, available_items_count].min
    end

    def calculate_distributed_positions(total_count, target_count)
      spacing = (total_count.to_f / target_count).ceil
      positions = []
      current_pos = 0

      target_count.times do
        break if current_pos >= total_count

        positions << current_pos
        current_pos += spacing
      end

      positions
    end
  end
end
