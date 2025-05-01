# frozen_string_literal: true

require_relative 'base_strategy'

module TypeBalancer
  module Strategies
    # Implements a sliding window approach to balance items
    class SlidingWindowStrategy < BaseStrategy
      def initialize(items:, type_field:, types: nil, window_size: 10)
        super(items: items, type_field: type_field, types: types)
        @window_size = window_size
        @types = types || extract_types
      end

      def balance
        return [] if @items.empty?

        validate_items!

        type_queues = group_items_by_type
        result = []
        used_items = Set.new

        # If there's only one type, return items in original order
        return @items.dup if type_queues.size == 1

        # Calculate overall ratios
        total_items = @items.size.to_f
        type_ratios = type_queues.transform_values { |items| items.size / total_items }

        # Process items in windows
        while result.size < @items.size
          window_size = [[@window_size, @items.size - result.size].min, 1].max
          window_items = balance_window(type_queues, type_ratios, window_size, used_items)

          # If we couldn't fill the window, add remaining items in their original order
          if window_items.empty?
            # Add remaining items in their original order
            @items.each do |item|
              next if used_items.include?(item)

              result << item
              used_items.add(item)
            end
            break
          end

          # Add window items to result
          window_items.each do |item|
            next if used_items.include?(item)

            result << item
            used_items.add(item)
          end
        end

        result
      end

      private

      def balance_window(type_queues, type_ratios, window_size, used_items)
        window_items = []
        target_counts = calculate_window_targets(type_ratios, window_size)
        current_counts = Hash.new(0)

        while window_items.size < window_size
          type_to_add = find_next_type(type_ratios, current_counts, target_counts, type_queues, used_items)
          break unless type_to_add

          # Find next available item of this type that hasn't been used
          next_item = nil
          type_queues[type_to_add].each do |item|
            unless used_items.include?(item)
              next_item = item
              break
            end
          end
          break unless next_item

          window_items << next_item
          current_counts[type_to_add] += 1
        end

        window_items
      end

      def calculate_window_targets(type_ratios, window_size)
        # Initial calculation based on ratios
        initial_targets = type_ratios.transform_values { |ratio| (window_size * ratio).floor }

        # Ensure minimum representation
        min_count = 1
        type_ratios.each_key do |type|
          initial_targets[type] = [initial_targets[type], min_count].max if type_ratios[type].positive?
        end

        # Adjust if we've exceeded window size
        total = initial_targets.values.sum
        if total > window_size
          scale_factor = window_size.to_f / total
          initial_targets.transform_values! { |count| (count * scale_factor).floor }
        end

        # Distribute remaining slots to maintain ratios
        remaining = window_size - initial_targets.values.sum
        if remaining.positive?
          sorted_types = type_ratios.sort_by { |_, ratio| -ratio }.map(&:first)
          remaining.times { |i| initial_targets[sorted_types[i % sorted_types.size]] += 1 }
        end

        initial_targets
      end

      def find_next_type(type_ratios, current_counts, target_counts, type_queues, used_items)
        # Calculate current proportions
        total_current = current_counts.values.sum.to_f
        current_ratios = if total_current.zero?
                           type_ratios.dup
                         else
                           current_counts.transform_values { |count| count / total_current }
                         end

        # Find the type that's most behind its target
        type_ratios.keys.select do |type|
          next false if type_queues[type].all? { |item| used_items.include?(item) }
          next false if current_counts[type] >= target_counts[type]

          true
        end.min_by do |type|
          current_ratio = current_ratios[type] || 0
          target_ratio = type_ratios[type]
          current_ratio - target_ratio
        end
      end
    end
  end
end
