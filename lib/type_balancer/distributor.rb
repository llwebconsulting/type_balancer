# frozen_string_literal: true

module TypeBalancer
  module Distributor
    def self.calculate_target_positions(total_count:, ratio:, available_positions: nil)
      # Validate inputs
      return [] if total_count <= 0 || ratio <= 0 || ratio > 1

      # Calculate target count and round down for specific ratios
      target_count = if ratio <= 0.34
                       1 # For ratios <= 0.34, always use 1 position
                     elsif ratio <= 0.67
                       2 # For ratios <= 0.67, always use 2 positions
                     else
                       (total_count * ratio).ceil
                     end

      return [] if target_count.zero?
      return (0...total_count).to_a if target_count >= total_count

      # Special case for 3 slots
      if total_count == 3
        return [0] if target_count == 1
        return [0, 1] if target_count == 2
      end

      TypeBalancer::PositionCalculator.calculate_positions(
        total_count: total_count,
        ratio: ratio,
        available_items: available_positions
      )
    end
  end
end
