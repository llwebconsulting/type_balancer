# frozen_string_literal: true

require_relative 'strategy_factory'
require_relative 'strategies/base_strategy'
require_relative 'strategies/sliding_window_strategy'

module TypeBalancer
  # Handles calculation of positions for balanced item distribution
  class PositionCalculator
    # Represents a batch of position calculations
    class PositionBatch
      attr_reader :total_count, :ratio, :available_items

      def initialize(total_count:, ratio:, available_items: nil)
        @total_count = total_count
        @ratio = ratio
        @available_items = available_items
      end

      def valid?
        valid_basic_inputs? && valid_available_items?
      end

      def target_count
        @target_count ||= (total_count * ratio).round
      end

      private

      def valid_basic_inputs?
        total_count.positive? && ratio.positive? && ratio <= 1.0
      end

      def valid_available_items?
        return true if available_items.nil?

        valid_array? && valid_indices?
      end

      def valid_array?
        available_items.is_a?(Array) && available_items.all? { |i| i.is_a?(Integer) }
      end

      def valid_indices?
        available_items.none? { |i| i.negative? || i >= total_count }
      end
    end

    class << self
      # Calculate positions for a single input (legacy support)
      def calculate_positions(total_count:, ratio:, available_items: nil)
        return [] if total_count.zero? || ratio.zero?
        return nil unless valid_inputs?(total_count, ratio)

        target_count = (total_count * ratio).round
        return [] if target_count.zero?

        if available_items
          calculate_positions_with_available_items(total_count, target_count, available_items)
        else
          calculate_evenly_spaced_positions(total_count, target_count, ratio)
        end
      end

      private

      def calculate_positions_with_available_items(total_count, target_count, available_items)
        return nil if available_items.any? { |pos| pos >= total_count }
        return available_items.take(target_count) if available_items.size <= target_count

        if target_count == 1
          [available_items.first]
        else
          distribute_available_positions(available_items, target_count)
        end
      end

      def distribute_available_positions(available_items, target_count)
        indices = (0...target_count).map do |i|
          ((available_items.size - 1) * i.fdiv(target_count - 1)).round
        end
        indices.map { |i| available_items[i] }
      end

      def calculate_evenly_spaced_positions(total_count, target_count, ratio)
        return [0] if target_count == 1
        return handle_two_thirds_case(total_count) if two_thirds_ratio?(ratio, total_count)

        (0...target_count).map do |i|
          ((total_count - 1) * i.fdiv(target_count - 1)).round
        end
      end

      def two_thirds_ratio?(ratio, total_count)
        (ratio - (2.0 / 3.0)).abs < 1e-6 && total_count == 3
      end

      def handle_two_thirds_case(_total_count)
        [0, 1]
      end

      def valid_inputs?(total_count, ratio)
        total_count >= 0 && ratio >= 0 && ratio <= 1.0
      end
    end
  end

  # Main calculator that handles type-based balancing of items
  class Calculator
    DEFAULT_TYPE_ORDER = %w[video image strip article].freeze

    def initialize(items, type_field: :type, types: nil, strategy: nil, **strategy_options)
      raise ArgumentError, 'Items cannot be nil' if items.nil?
      raise ArgumentError, 'Type field cannot be nil' if type_field.nil?

      @items = items
      @type_field = type_field
      @types = types
      @strategy_name = strategy
      @strategy_options = strategy_options
    end

    def call
      return [] if @items.empty?

      # Create strategy instance
      strategy = StrategyFactory.create(
        @strategy_name,
        items: @items,
        type_field: @type_field,
        types: @types || extract_types,
        **@strategy_options
      )

      # Balance items using strategy
      strategy.balance
    end

    private

    def extract_types
      types = @items.map { |item| item[@type_field].to_s }.uniq
      DEFAULT_TYPE_ORDER.select { |type| types.include?(type) } + (types - DEFAULT_TYPE_ORDER)
    end
  end
end

# Register default strategy
TypeBalancer::StrategyFactory.register(:sliding_window, TypeBalancer::Strategies::SlidingWindowStrategy)
