# frozen_string_literal: true

module TypeBalancer
  class PositionCalculator
    class << self
      def calculate_positions(total_count:, ratio:, available_items: nil)
        return [] unless valid_input?(total_count, ratio)

        target_count = (total_count * ratio).ceil
        return [] if target_count.zero?
        return (0...total_count).to_a if target_count >= total_count

        if available_items
          calculate_with_available_items(available_items, target_count)
        else
          calculate_evenly_spaced_positions(total_count, target_count)
        end
      end

      private

      def valid_input?(total_count, ratio)
        total_count.positive? && ratio.positive? && ratio <= 1
      end

      def calculate_with_available_items(available_items, target_count)
        return [] if available_items.empty?
        return [available_items.first] if target_count == 1
        return [available_items.first, available_items.last] if target_count == 2

        available_items.take(target_count)
      end

      def calculate_evenly_spaced_positions(total_count, target_count)
        return [0] if target_count == 1

        max_pos = total_count - 1
        return [0, max_pos] if target_count == 2

        calculate_multi_position_spacing(max_pos, target_count)
      end

      def calculate_multi_position_spacing(max_pos, target_count)
        first_gap = (max_pos / (target_count - 1.0)).ceil
        positions = [0]
        remaining_gaps = target_count - 2
        remaining_space = max_pos - first_gap

        if remaining_gaps.positive?
          step = remaining_space / remaining_gaps.to_f
          (1...target_count - 1).each do |i|
            positions << (first_gap + ((i - 1) * step)).round
          end
        end

        positions << max_pos
        positions
      end
    end
  end
end
