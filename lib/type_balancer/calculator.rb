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
        batch = PositionBatch.new(
          total_count: total_count,
          ratio: ratio,
          available_items: available_items
        )

        calculate_batch(batch)
      end

      # Calculate positions for a batch of inputs
      # @param batch [PositionBatch] The batch configuration
      # @param iterations [Integer] Number of times to calculate (for benchmarking)
      # @return [Array<Integer>, nil] Array of calculated positions or nil if invalid
      def calculate_batch(batch, iterations = 1)
        return nil unless batch.valid?
        return [] if batch.total_count.zero? || batch.target_count.zero?
        return [0] if batch.target_count == 1

        if batch.available_items
          calculate_with_available(batch)
        else
          calculate_without_available(batch, iterations)
        end
      end

      private

      def calculate_without_available(batch, iterations)
        spacing = batch.total_count.to_f / batch.target_count

        # Process all iterations (for benchmarking)
        positions = nil
        iterations.times do
          positions = Array.new(batch.target_count) do |i|
            ideal_pos = i * spacing
            ideal_pos.round.clamp(0, batch.total_count - 1)
          end
        end

        positions
      end

      def calculate_with_available(batch)
        return batch.available_items.take(batch.target_count) if batch.available_items.size <= batch.target_count

        spacing = (batch.available_items.size - 1).to_f / (batch.target_count - 1)
        Array.new(batch.target_count) do |i|
          idx = (i * spacing).round
          batch.available_items[idx]
        end
      end
    end
  end

  # Main calculator that handles type-based balancing of items
  class Calculator
    def initialize(items, type_field:, types: nil)
      @items = items
      @type_field = type_field
      @types = types || extract_types
    end

    def call
      return [] if @items.empty?

      items_by_type = @types.map { |type| items_of_type(type) }
      target_positions = calculate_target_positions(items_by_type)
      place_items_at_positions(items_by_type, target_positions)
    end

    private

    def items_of_type(type)
      @items.select { |item| item[@type_field].to_s == type.to_s }
    end

    def calculate_target_positions(items_by_type)
      total_count = @items.size
      target_positions = []

      items_by_type.each_with_index do |_items, index|
        ratio = if items_by_type.size == 1
                  1.0
                elsif index.zero?
                  0.4
                else
                  0.3
                end

        positions = PositionCalculator.calculate_positions(
          total_count: total_count,
          ratio: ratio
        )
        target_positions << positions
      end

      target_positions
    end

    def place_items_at_positions(items_by_type, target_positions)
      result = Array.new(@items.size)
      place_items_at_target_positions(items_by_type, target_positions, result)
      fill_remaining_positions(items_by_type, target_positions, result)
      result.compact
    end

    def place_items_at_target_positions(items_by_type, target_positions, result)
      items_by_type.each_with_index do |items, type_index|
        positions = target_positions[type_index]
        next if positions.empty?

        items.each_with_index do |item, item_index|
          break if item_index >= positions.size

          result[positions[item_index]] = item
        end
      end
    end

    def fill_remaining_positions(items_by_type, target_positions, result)
      remaining_items = collect_remaining_items(items_by_type, target_positions)
      fill_empty_slots(result, remaining_items)
    end

    def collect_remaining_items(items_by_type, target_positions)
      items_by_type.flat_map.with_index do |items, type_index|
        positions = target_positions[type_index]
        items[positions.size..]
      end.compact
    end

    def fill_empty_slots(result, remaining_items)
      result.each_with_index do |item, index|
        next unless item.nil?
        break if remaining_items.empty?

        result[index] = remaining_items.shift
      end
    end

    def extract_types
      @items.map { |item| item[@type_field].to_s }.uniq
    end
  end
end
