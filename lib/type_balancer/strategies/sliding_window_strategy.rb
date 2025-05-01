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
        return @items.dup if single_type?

        type_queues   = group_items_by_type
        type_ratios   = calculate_type_ratios(type_queues)

        process_windows(type_queues, type_ratios)
      end

      private

      def single_type?
        group_items_by_type.size == 1
      end

      def calculate_type_ratios(type_queues)
        total_items = @items.size.to_f
        type_queues.transform_values { |list| list.size / total_items }
      end

      def process_windows(type_queues, type_ratios)
        result     = []
        used_items = Set.new

        until result.size == @items.size
          size   = next_window_size(result)
          window = balance_window(type_queues, type_ratios, size, used_items)

          if window.empty?
            append_remaining(result, used_items)
          else
            window.each do |item|
              next if used_items.include?(item)

              result << item
              used_items.add(item)
            end
          end
        end

        result
      end

      def next_window_size(result)
        remaining = @items.size - result.size
        [[@window_size, remaining].min, 1].max
      end

      def append_remaining(result, used_items)
        @items.each do |item|
          next if used_items.include?(item)

          result << item
          used_items.add(item)
        end
      end

      def balance_window(type_queues, type_ratios, window_size, used_items)
        window_items   = []
        target_counts  = calculate_window_targets(type_ratios, window_size)
        current_counts = Hash.new(0)

        while window_items.size < window_size
          type_to_add = find_next_type(type_ratios, current_counts, target_counts, type_queues, used_items)
          break unless type_to_add

          next_item = type_queues[type_to_add].find { |i| !used_items.include?(i) }
          break unless next_item

          window_items << next_item
          current_counts[type_to_add] += 1
        end

        window_items
      end

      def calculate_window_targets(type_ratios, window_size)
        targets = type_ratios.transform_values { |ratio| (window_size * ratio).floor }
        ensure_minimum_representation(targets, type_ratios)
        scale_down_if_needed(targets, window_size)
        distribute_remaining_slots(targets, type_ratios, window_size)
        targets
      end

      def find_next_type(type_ratios, current_counts, target_counts, type_queues, used_items)
        current_ratios = compute_current_ratios(current_counts, type_ratios)
        eligible = eligible_types(type_ratios, current_counts, target_counts, type_queues, used_items)
        eligible.min_by { |t| (current_ratios[t] || 0) - type_ratios[t] }
      end

      def ensure_minimum_representation(targets, type_ratios)
        type_ratios.each_key do |t|
          targets[t] = 1 if type_ratios[t].positive? && targets[t] < 1
        end
      end

      def scale_down_if_needed(targets, window_size)
        total = targets.values.sum
        return unless total > window_size

        factor = window_size.to_f / total
        targets.transform_values! { |count| (count * factor).floor }
      end

      def distribute_remaining_slots(targets, type_ratios, window_size)
        remaining = window_size - targets.values.sum
        return unless remaining.positive?

        sorted = type_ratios.sort_by { |_t, r| -r }.map(&:first)
        remaining.times { |i| targets[sorted[i % sorted.size]] += 1 }
      end

      def compute_current_ratios(current_counts, type_ratios)
        total = current_counts.values.sum.to_f
        return type_ratios.dup if total.zero?

        current_counts.transform_values { |c| c / total }
      end

      def eligible_types(type_ratios, current_counts, target_counts, type_queues, used_items)
        type_ratios.keys.select do |t|
          type_queues[t].any? { |i| !used_items.include?(i) } &&
            current_counts[t] < target_counts[t]
        end
      end
    end
  end
end
