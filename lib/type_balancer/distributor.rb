# frozen_string_literal: true

module TypeBalancer
  module Distributor
    class << self
      def calculate_target_positions(total_count, available_count, ratio, available_items = nil)
        # Input validation
        return [] if total_count <= 0 || available_count <= 0 || ratio <= 0 || ratio > 1
        return [] if available_count > total_count

        # Calculate target count
        target_count = (total_count * ratio).ceil
        target_count = [target_count, available_count].min

        # Special cases
        return [] if target_count.zero?
        return [available_items&.first || 0] if target_count == 1

        # If specific positions are available, use those
        if available_items
          # Ensure available_items are valid
          available_items = available_items.select { |pos| pos >= 0 && pos < total_count }.sort
          return [] if available_items.empty?

          # If we have fewer available positions than target count, use what we have
          target_count = [target_count, available_items.size].min

          # Calculate spacing within available positions
          step = (available_items.size - 1).to_f / (target_count - 1)
          return target_count.times.map { |i| available_items[(i * step).round] }
        end

        # Calculate spacing for the general case
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
