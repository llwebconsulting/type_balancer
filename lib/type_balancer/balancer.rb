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

      # Place primary type (first type) at calculated positions
      primary_items = place_primary_type(collection_manager, total_count)

      # Place remaining types alternating in the gaps
      place_remaining_types(collection_manager, primary_items)

      collection_manager.result
    end

    def place_primary_type(collection_manager, total_count)
      primary_type = @types.first
      primary_items = items_of_type(primary_type)

      positions = @distribution_calculator.calculate_target_positions(
        total_count,
        primary_items.size
      )
      collection_manager.place_at_positions(primary_items.first(positions.size), positions)

      # Return unused primary items for gap filling
      primary_items[positions.size..]
    end

    def place_remaining_types(collection_manager, unused_primary_items)
      remaining_types = @types[1..]
      return if remaining_types.empty?

      # Get items for each remaining type
      remaining_items = remaining_types.map { |type| items_of_type(type) }

      # Add unused primary items to the remaining items
      all_remaining_items = [unused_primary_items, *remaining_items].compact.reject(&:empty?)

      if all_remaining_items.size == 1
        # If only one type of items left, fill all gaps with it
        collection_manager.fill_remaining_gaps([all_remaining_items.first])
      else
        # For two or more types, fill gaps evenly among all types
        collection_manager.fill_remaining_gaps(all_remaining_items)
      end
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
