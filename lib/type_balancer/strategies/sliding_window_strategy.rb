# frozen_string_literal: true

require_relative 'base_strategy'

module TypeBalancer
  module Strategies
    # Implements an efficient sliding window approach for balancing items
    # This strategy uses array-based indexing and pre-calculated ratios for optimal performance
    class SlidingWindowStrategy < BaseStrategy
      DEFAULT_BATCH_SIZE = 1000

      # rubocop:disable Metrics/ParameterLists
      def initialize(items:, type_field:, types: nil, type_order: nil, window_size: 10, batch_size: DEFAULT_BATCH_SIZE)
        super(items: items, type_field: type_field, types: types, type_order: type_order)
        @window_size = window_size
        @batch_size  = batch_size
        @types       = types || extract_types
      end
      # rubocop:enable Metrics/ParameterLists

      def balance
        return [] if @items.empty?

        validate_items!
        return @items.dup if single_type?

        @type_queues = build_type_queues
        @type_ratios = calculate_type_ratios

        if @items.size > @batch_size
          process_large_collection
        else
          process_single_batch
        end
      end

      private

      def single_type?
        @items.map { |item| item[@type_field].to_s }.uniq.one?
      end

      def build_type_queues
        queues = {}
        ordered_types = @type_order || @types
        ordered_types.each { |t| queues[t] = [] }

        @items.each_with_index do |item, idx|
          t = item[@type_field].to_s
          queues[t] << idx if queues.key?(t)
        end

        queues
      end

      def calculate_type_ratios
        total = @items.size.to_f
        @type_queues.transform_values { |inds| inds.size / total }
      end

      def process_large_collection
        result       = Array.new(@items.size)
        type_indices = initialize_type_indices

        (0...@items.size).step(@batch_size) do |start_idx|
          end_idx = [start_idx + @batch_size, @items.size].min
          process_batch_range(result, type_indices, start_idx, end_idx)
        end

        result.compact
      end

      def process_single_batch
        result = Array.new(@items.size)
        process_batch_range(result, initialize_type_indices, 0, @items.size)
        result.compact
      end

      def initialize_type_indices
        @type_queues.transform_values { 0 }
      end

      def process_batch_range(result, type_indices, start_idx, end_idx)
        window_start = start_idx

        while window_start < end_idx
          window_size = compute_window_size(window_start, end_idx)
          positions   = calculate_window_positions(window_size)
          apply_window_positions(positions, window_start, window_size, result, type_indices)
          window_start += window_size
        end

        fill_gaps(result, type_indices, start_idx, end_idx)
      end

      def compute_window_size(start_pos, end_pos)
        [[start_pos + @window_size, end_pos].min - start_pos, 1].max
      end

      def calculate_window_positions(window_size)
        WindowSlotCalculator.new(@type_ratios, @type_order).calculate(window_size)
      end

      def apply_window_positions(positions, start_pos, size, result, type_indices)
        ordered_types = @type_order || @type_queues.keys
        ordered_types.each do |type|
          next unless positions[type]

          positions[type].times do
            break if type_indices[type] >= @type_queues[type].size

            pos = find_next_position(result, start_pos, start_pos + size)
            break unless pos

            result[pos] = @items[@type_queues[type][type_indices[type]]]
            type_indices[type] += 1
          end
        end
      end

      def find_next_position(result, start_pos, end_pos)
        (start_pos...end_pos).find { |i| result[i].nil? }
      end

      def fill_gaps(result, type_indices, start_idx, end_idx)
        ordered_types = @type_order || @type_queues.keys

        (start_idx...end_idx).each do |i|
          next unless result[i].nil?

          ordered_types.each do |type|
            next unless @type_queues[type] && type_indices[type] < @type_queues[type].size

            result[i] = @items[@type_queues[type][type_indices[type]]]
            type_indices[type] += 1
            break
          end
        end
      end

      class WindowSlotCalculator
        def initialize(type_ratios, type_order)
          @type_ratios = type_ratios
          @type_order  = type_order
        end

        def calculate(window_size)
          slots = build_initial_slots(window_size)
          distribute_remaining_slots(slots)
          slots
        end

        private

        def build_initial_slots(window_size)
          slots             = {}
          remaining_ratio   = 1.0
          @remaining_slots  = window_size

          ordered_types.each do |t|
            ratio  = @type_ratios[t] || 0
            target = calculate_target(window_size, ratio, remaining_ratio)
            slots[t] = target
            @remaining_slots -= target
            remaining_ratio -= ratio
          end

          slots
        end

        def calculate_target(size, ratio, rem_ratio)
          tgt = (size * (ratio / rem_ratio)).floor
          tgt = [tgt, @remaining_slots].min
          tgt = 1 if ratio.positive? && tgt.zero? && @remaining_slots.positive?
          tgt
        end

        def distribute_remaining_slots(slots)
          return if @remaining_slots <= 0

          types = sorted_distribution_types
          @remaining_slots.times { |i| slots[types[i % types.size]] += 1 }
        end

        def ordered_types
          @type_order || @type_ratios.keys
        end

        def sorted_distribution_types
          if @type_order
            @type_order & @type_ratios.keys
          else
            @type_ratios.sort_by { |_t, r| -r }.map(&:first)
          end
        end
      end
    end
  end
end
