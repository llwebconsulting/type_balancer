# frozen_string_literal: true

module TypeBalancer
  module Distributor
    class << self
      def calculate_target_positions(total_count, available_count, ratio)
        # Input validation
        return [] if total_count <= 0 || available_count <= 0 || ratio <= 0 || ratio > 1
        return [] if available_count > total_count

        # Calculate target count
        target_count = (total_count * ratio).ceil
        target_count = [target_count, available_count].min

        # Special cases
        return [] if target_count == 0
        return [0] if target_count == 1

        # Calculate spacing
        spacing = total_count.to_f / target_count

        # Generate positions
        positions = Array.new(target_count)
        target_count.times do |i|
          # Calculate ideal position
          ideal_pos = i * spacing

          # Round to nearest integer, ensuring we don't exceed bounds
          pos = ideal_pos.round
          pos = [pos, total_count - 1].min
          pos = [pos, 0].max

          positions[i] = pos
        end

        # Ensure positions are unique and sorted
        positions.uniq!
        positions.sort!

        positions
      end
    end
  end
end
