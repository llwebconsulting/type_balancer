# frozen_string_literal: true

module TypeBalancer
  # Main class responsible for balancing items in a collection based on their types.
  # It uses a distribution calculator to determine optimal positions for each type
  # and a gap filler strategy to place items in the final sequence.
  class Balancer
    def initialize(collection, type_field:, types: nil, distribution_calculator: DistributionCalculator.new)
      @collection = collection
      @type_field = type_field
      @types = types || extract_unique_types
      @distribution_calculator = distribution_calculator
    end

    def call
      return [] if @collection.empty?
      return @collection if single_type?

      balance_collection
    end

    private

    def single_type?
      @types.any? { |type| items_of_type(type).size == @collection.size }
    end

    def balance_collection
      total_count = @collection.size
      collection_manager = OrderedCollectionManager.new(total_count)

      # Group items by type
      items_by_type = @types.map { |type| items_of_type(type) }

      # Calculate target positions for each type
      target_positions_by_type = items_by_type.map.with_index do |items, index|
        ratio = if @types.size == 1
                  1.0 # Use all positions for single type
                elsif index.zero?
                  0.4  # Higher ratio for first type
                else
                  0.3  # Equal ratio for remaining types
                end

        @distribution_calculator.calculate_target_positions(
          total_count,
          items.size,
          ratio
        )
      end

      # Place items at their positions
      items_by_type.zip(target_positions_by_type).each do |items, positions|
        next if positions.empty?

        collection_manager.place_at_positions(items.first(positions.size), positions)
      end

      # Get remaining items
      remaining_items = items_by_type.zip(target_positions_by_type).flat_map do |items, positions|
        items[positions.size..]
      end.compact

      # Fill remaining gaps
      collection_manager.fill_remaining_gaps([remaining_items]) if remaining_items.any?

      # Return the result
      collection_manager.result
    end

    def items_of_type(type)
      @collection.select { |item| item_type(item) == type }
    end

    def item_type(item)
      if item.respond_to?(@type_field)
        item.send(@type_field)
      elsif item.respond_to?(:[])
        item[@type_field.to_s] || item[@type_field.to_sym]
      else
        raise Error, "Cannot access type field '#{@type_field}' on item #{item}"
      end
    end

    def extract_unique_types
      @collection.map { |item| item_type(item) }.uniq
    end
  end
end
