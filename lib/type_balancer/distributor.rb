# frozen_string_literal: true

module TypeBalancer
  class Distributor
    class << self
      def calculate_target_positions(total_count, available_items, target_ratio)
        return [] if total_count.zero? || available_items.zero?
        return [0] if total_count == 1

        # For equal distribution (e.g., 3 types with ratio ~0.33 each)
        if target_ratio.between?(0.3, 0.35)
          # Calculate positions with equal spacing
          spacing = total_count.to_f / available_items
          positions = available_items.times.map { |i| (i * spacing).floor }
          positions = positions.map { |pos| [pos, total_count - 1].min }.uniq

          # If we don't have enough positions, add more at the end
          while positions.size < available_items && positions.last < total_count - 1
            next_pos = positions.last + 1
            positions << next_pos
          end

          return positions
        end

        # Calculate the target number of positions based on the ratio
        target_positions = (total_count * target_ratio).ceil
        # We need at least enough positions for all available items
        target_positions = [target_positions, available_items].max
        target_positions = [target_positions, total_count].min

        # Calculate the ideal spacing between items
        spacing = total_count.to_f / target_positions

        # Generate positions with even spacing
        positions = []
        target_positions.times do |i|
          pos = (i * spacing).floor
          pos = [pos, total_count - 1].min # Ensure we don't exceed total_count
          positions << pos
        end

        # Adjust positions to be more evenly distributed if needed
        positions.each_with_index do |pos, i|
          next if i.zero? # Skip first position

          if pos <= positions[i - 1] # If current position overlaps with previous
            positions[i] = positions[i - 1] + 1 # Move it one step forward
          end
        end

        # Ensure we don't exceed total_count and have unique positions
        positions = positions.map { |pos| [pos, total_count - 1].min }.uniq

        # If we have fewer positions than available items, add more at the end
        while positions.size < available_items && positions.last < total_count - 1
          next_pos = positions.last + 1
          positions << next_pos
        end

        # If we still don't have enough positions, add them at the beginning
        while positions.size < available_items
          next_pos = positions.first - 1
          next_pos = [next_pos, 0].max
          positions.unshift(next_pos) unless positions.include?(next_pos)
        end

        positions
      end
    end
  end
end
