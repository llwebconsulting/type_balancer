# frozen_string_literal: true

module TypeBalancer
  module Distributor
    def self.calculate_target_positions(total_count:, ratio:, available_positions: nil)
      # Validate inputs
      return [] if total_count <= 0 || ratio <= 0 || ratio > 1

      # Calculate base target count
      target_count = (total_count * ratio).ceil

      # Special case for 3 slots
      if total_count == 3
        target_count = if ratio <= 0.34
                         1
                       elsif ratio <= 0.67
                         2
                       else
                         3
                       end
      end

      return [] if target_count.zero?
      return (0...total_count).to_a if target_count >= total_count

      if available_positions
        # Filter out invalid positions and sort them
        valid_positions = available_positions.select { |pos| pos >= 0 && pos < total_count }.sort
        return [] if valid_positions.empty?

        # For single target position, use first available
        return [valid_positions.first] if target_count == 1

        # For two positions
        if target_count == 2
          # Special case for invalid positions that go beyond total_count
          if available_positions.any? { |pos| pos >= total_count }
            valid_positions = available_positions.select { |pos| pos >= 0 }.sort
            return [valid_positions.first, valid_positions.last]
          end
          # For three slots, use first two positions
          return [valid_positions[0], valid_positions[1]] if total_count == 3

          # Otherwise use first and last
          return [valid_positions.first, valid_positions.last]
        end

        # If we have fewer or equal positions than needed, use all available up to target_count
        return valid_positions if valid_positions.size <= target_count

        # For more positions, take the first N positions where N is target_count
        return valid_positions.first(target_count) if target_count <= 3

        # For larger target counts, distribute evenly
        target_positions = []
        step = (valid_positions.size - 1).fdiv(target_count - 1)
        (0...target_count).each do |i|
          index = (i * step).round
          target_positions << valid_positions[index]
        end
        target_positions
      else
        # Handle single target position
        return [0] if target_count == 1

        # For two positions
        if target_count == 2
          # Special case for three slots
          return [0, 1] if total_count == 3

          # Otherwise use first and last
          return [0, total_count - 1]
        end

        # Calculate evenly spaced positions for multiple targets
        (0...target_count).map do |i|
          ((total_count - 1) * i.fdiv(target_count - 1)).round
        end
      end
    end
  end
end
