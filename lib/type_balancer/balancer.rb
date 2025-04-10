# frozen_string_literal: true

require_relative 'ratio_calculator'
require_relative 'batch_processing'

module TypeBalancer
  # Handles balancing of items across batches based on type ratios
  class Balancer
    # Initialize a new Balancer instance
    #
    # @param types [Array<String>] List of valid types
    # @param batch_size [Integer] Size of each batch
    # @param type_order [Array<String>, nil] Optional order of types
    def initialize(types, batch_size = 10, type_order: nil)
      @types = Array(types)
      @batch_size = batch_size
      @type_order = type_order || @types.dup

      raise ArgumentError, 'Types cannot be empty' if @types.empty?
      raise ArgumentError, 'Batch size must be positive' unless @batch_size.positive?
      raise ArgumentError, 'Type order must contain all types' unless (@type_order - @types).empty?
    end

    # Main entry point for balancing items
    #
    # @param collection [Array<Hash>, Hash<String, Array>] Collection of items to balance
    # @return [Array<Array>] Balanced batches of items
    def call(collection)
      items_by_type = collection.is_a?(Hash) ? collection : group_items_by_type(collection)
      validate_items_by_type!(items_by_type)
      balance(items_by_type)
    end

    # Balance items into batches based on type ratios
    #
    # @param items_by_type [Hash<String, Array>] Items grouped by type
    # @return [Array<Array>] Balanced batches of items
    def balance(items_by_type)
      return [] if items_by_type.empty?

      # First, calculate how many times we need to repeat each item
      total_items = items_by_type.values.sum(&:size)
      ratios = calculate_ratios(items_by_type)

      # Create expanded arrays for each type based on ratios
      expanded_items = {}
      items_by_type.each do |type, items|
        target_count = (total_items * ratios[type]).round
        repeats = (target_count.to_f / items.size).ceil
        expanded_items[type] = items * repeats
      end

      # Now distribute items while maintaining relative ratios and type order
      result = []
      current_positions = Hash.new(0)

      total_items.times do |_|
        # Use type_order to determine which type to process next
        target_type = @type_order.find do |type|
          current_ratio = current_positions[type].to_f / total_items
          target_ratio = ratios[type]
          current_ratio < target_ratio && !expanded_items[type].empty?
        end

        # If no type from type_order is available, fall back to the original method
        target_type ||= find_next_type(ratios, current_positions, total_items)

        # Get next item of this type
        items = expanded_items[target_type]
        pos = current_positions[target_type]

        # Add item and update position
        result << items[pos % items_by_type[target_type].size]
        current_positions[target_type] += 1
      end

      # Ensure we have exactly the right number of items and split into batches
      result = result[0...total_items]
      result.each_slice(@batch_size).to_a
    end

    private

    def validate_items_by_type!(items_by_type)
      raise ArgumentError, 'Collection cannot be empty' if items_by_type.empty?

      # Validate that all types in the collection are allowed
      invalid_types = items_by_type.keys - @types
      return if invalid_types.empty?

      raise TypeBalancer::Error, "Invalid types: #{invalid_types.join(', ')}. Allowed types: #{@types.join(', ')}"
    end

    def extract_type(item)
      case item
      when Hash
        item[:type] || item['type'] or raise TypeError, 'Hash is missing type key'
      else
        item.type
      end
    end

    def group_items_by_type(collection)
      collection.group_by { |item| extract_type(item) }
    end

    def calculate_ratios(items_by_type)
      return { @types.first => 1.0 } if @types.size == 1

      # Calculate total count and type counts
      total_count = items_by_type.values.sum(&:size)

      # Create a hash of type counts
      type_counts = @types.to_h { |type| [type, items_by_type.fetch(type, []).size] }

      # Ensure minimum representation for each type
      min_ratio = 0.1
      remaining_ratio = 1.0 - (min_ratio * @types.size)

      ratios = type_counts.transform_values do |count|
        min_ratio + ((count / total_count) * remaining_ratio)
      end

      # Normalize ratios to sum to 1.0
      sum = ratios.values.sum
      ratios.transform_values { |ratio| ratio / sum }
    end

    def find_next_type(ratios, current_positions, total_count)
      @types.min_by do |type|
        current_ratio = current_positions[type].to_f / total_count
        target_ratio = ratios[type]
        current_ratio - target_ratio
      end
    end
  end
end
