# frozen_string_literal: true

module TypeBalancer
  # Calculates the optimal distribution of items by type in a sequence.
  # For each type, it determines the ideal positions where items of that type
  # should be placed to achieve a balanced distribution.
  class DistributionCalculator
    def initialize(target_ratio = 0.2)
      @target_ratio = target_ratio
    end

    def calculate_target_positions(total_count, available_items_count, target_ratio = @target_ratio)
      # Use the C extension for the calculation
      TypeBalancer::Distributor.calculate_target_positions(
        total_count,
        available_items_count,
        target_ratio
      )
    end
  end
end
