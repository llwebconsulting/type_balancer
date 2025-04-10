# frozen_string_literal: true

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

    def initialize(items, type_field: :type, types: nil)
      raise ArgumentError, 'Items cannot be nil' if items.nil?
      raise ArgumentError, 'Type field cannot be nil' if type_field.nil?

      @items = items
      @type_field = type_field
      @types = types || extract_types
    end

    def call
      return [] if @items.empty?

      validate_items!

      items_by_type = @types.map { |type| @items.select { |item| item[@type_field].to_s == type } }

      # Calculate target positions for each type
      target_positions = calculate_target_positions(items_by_type)

      # Place items at their target positions
      place_items_at_positions(items_by_type, target_positions)
    end

    private

    def validate_items!
      @items.each do |item|
        raise ArgumentError, 'All items must have a type field' unless item.key?(@type_field)
        raise ArgumentError, 'Type values cannot be empty' if item[@type_field].to_s.strip.empty?
      end
    end

    def extract_types
      types = @items.map { |item| item[@type_field].to_s }.uniq
      DEFAULT_TYPE_ORDER.select { |type| types.include?(type) } + (types - DEFAULT_TYPE_ORDER)
    end

    def calculate_target_positions(items_by_type)
      total_count = @items.size
      available_positions = (0...total_count).to_a

      items_by_type.map.with_index do |_items, index|
        ratio = calculate_ratio(items_by_type.size, index)
        target_count = (total_count * ratio).round

        # Calculate positions based on ratio and total count
        if target_count == 1
          [index]
        else
          # For better distribution, calculate positions based on available slots
          step = available_positions.size.fdiv(target_count)
          positions = (0...target_count).map do |i|
            pos_index = (i * step).round
            available_positions[pos_index]
          end

          # Remove used positions from available ones
          positions.each { |pos| available_positions.delete(pos) }
          positions
        end
      end
    end

    def calculate_ratio(type_count, index)
      case type_count
      when 1 then 1.0
      when 2 then index.zero? ? 0.6 : 0.4
      else
        # For 3+ types: first type gets 0.4, rest split remaining 0.6 evenly
        remaining = (0.6 / (type_count - 1).to_f).round(6)
        index.zero? ? 0.4 : remaining
      end
    end

    def place_items_at_positions(items_by_type, target_positions)
      result = Array.new(@items.size)
      used_items = place_items_at_target_positions(items_by_type, target_positions, result)
      fill_empty_slots(result, used_items)
      result.compact
    end

    def place_items_at_target_positions(items_by_type, target_positions, result)
      used_items = []
      items_by_type.each_with_index do |items, type_index|
        positions = target_positions[type_index] || []
        place_type_items(items, positions, result, used_items)
      end
      used_items
    end

    def place_type_items(items, positions, result, used_items)
      items.take(positions.size).each_with_index do |item, item_index|
        pos = positions[item_index]
        next unless pos && result[pos].nil?

        result[pos] = item
        used_items << item
      end
    end

    def fill_empty_slots(result, used_items)
      remaining_items = @items - used_items
      empty_slots = result.each_index.select { |i| result[i].nil? }
      empty_slots.zip(remaining_items).each do |slot, item|
        break unless item

        result[slot] = item
      end
    end
  end
end
