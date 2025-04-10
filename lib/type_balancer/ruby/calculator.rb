# frozen_string_literal: true

module TypeBalancer
  module Ruby
    # Pure Ruby implementation of position calculation
    class Calculator
      class << self
        def calculate_positions(total_count:, ratio:, available_items: nil)
          validate_inputs(total_count, ratio)
          return [] if total_count.zero?

          target_count = (total_count * ratio).round
          return [] if target_count.zero?

          if available_items
            validate_available_items(available_items, total_count)
            calculate_positions_with_available(total_count, target_count, available_items)
          else
            calculate_positions_without_available(total_count, target_count)
          end
        end

        private

        def validate_inputs(total_count, ratio)
          raise ArgumentError, "total_count must be >= 0, got #{total_count}" if total_count.negative?
          raise ArgumentError, "ratio must be between 0 and 1, got #{ratio}" if ratio.negative? || ratio > 1
        end

        def validate_available_items(available_items, total_count)
          unless available_items.is_a?(Array) && available_items.all? { |i| i.is_a?(Integer) }
            raise ArgumentError, 'available_items must be an array of integers'
          end

          return unless available_items.any? { |i| i.negative? || i >= total_count }

          raise ArgumentError, 'available_items must contain valid indices (0 to total_count-1)'
        end

        def calculate_positions_without_available(total_count, target_count)
          spacing = total_count.to_f / target_count
          positions = Array.new(target_count)

          target_count.times do |i|
            ideal_pos = i * spacing
            positions[i] = ideal_pos.round
          end

          positions
        end

        def calculate_positions_with_available(_total_count, target_count, available_items)
          return available_items.take(target_count) if available_items.size <= target_count

          spacing = (available_items.size - 1).to_f / (target_count - 1)
          positions = Array.new(target_count)

          target_count.times do |i|
            idx = (i * spacing).round
            positions[i] = available_items[idx]
          end

          positions
        end
      end
    end
  end
end
