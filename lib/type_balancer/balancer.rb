# frozen_string_literal: true

require_relative 'ratio_calculator'
require_relative 'batch_processing'
require_relative 'position_calculator'

module TypeBalancer
  # Handles balancing of items across batches based on type ratios
  class Balancer
    # Initialize a new Balancer instance
    #
    # @param types [Array<String>, nil] Optional types
    # @param type_order [Array<String>, nil] Optional order of types
    def initialize(types = nil, type_order: nil)
      @types = Array(types) if types
      @type_order = type_order
      validate_types! if @types
    end

    # Main entry point for balancing items
    #
    # @param collection [Array] Items to balance
    # @return [Array] Balanced items
    def call(collection)
      validate_collection!(collection)
      items_by_type = group_items_by_type(collection)
      validate_types_in_collection!(items_by_type)

      target_counts = calculate_target_counts(items_by_type)
      available_positions = (0...collection.size).to_a

      result = Array.new(collection.size)
      sorted_types = sort_types(items_by_type.keys)

      sorted_types.each do |type|
        items = items_by_type[type]
        target_count = target_counts[type]
        ratio = target_count.to_f / collection.size
        positions = PositionCalculator.calculate_positions(
          total_count: collection.size,
          ratio: ratio,
          available_items: available_positions
        )

        positions.each_with_index do |pos, idx|
          result[pos] = items[idx]
        end

        # Remove used positions from available positions
        available_positions -= positions
      end

      result.compact
    end

    private

    def validate_types!
      raise ArgumentError, 'Types cannot be empty' if @types.empty?
    end

    def validate_collection!(collection)
      raise ArgumentError, 'Collection cannot be empty' if collection.empty?
    end

    def validate_types_in_collection!(items_by_type)
      return unless @types

      invalid_types = items_by_type.keys - @types
      raise TypeBalancer::Error, "Invalid type(s): #{invalid_types.join(', ')}" if invalid_types.any?
    end

    def group_items_by_type(collection)
      collection.group_by do |item|
        extract_type(item)
      end
    end

    def extract_type(item)
      return item[:type] || item['type'] || raise(TypeBalancer::Error, 'Cannot access type field') if item.is_a?(Hash)

      begin
        item.type
      rescue NoMethodError
        raise TypeBalancer::Error, 'Cannot access type field'
      end
    end

    def calculate_target_counts(items_by_type)
      items_by_type.values.sum(&:size)
      items_by_type.transform_values(&:size)
    end

    def sort_types(types)
      return types.sort unless @type_order

      types.sort_by do |type|
        idx = @type_order.index(type)
        idx || Float::INFINITY
      end
    end
  end
end
