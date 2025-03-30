# frozen_string_literal: true

module TypeBalancer
  # Manages an ordered collection of items, providing methods to place items
  # at specific positions and fill gaps using different strategies.
  # This class acts as a facade for the gap filling functionality.
  class OrderedCollectionManager
    def initialize(size)
      @collection = Array.new(size)
      @item_order = [] # Track items in their original order
      @size = size
    end

    def place_at_positions(items, positions)
      # Store items in their original order
      @item_order.concat(items)

      # Place items at their positions
      positions.each_with_index do |pos, i|
        break if i >= items.size

        @collection[pos] = items[i] if pos >= 0 && pos < @size
      end
    end

    alias place_items_at_positions place_at_positions

    def fill_gaps_alternating(primary_items, secondary_items)
      # Add new items to the order list before filling gaps
      @item_order.concat(primary_items)
      @item_order.concat(secondary_items)

      # Find empty positions
      empty_positions = find_empty_positions
      return if empty_positions.empty?

      # Create a copy of the collection for filling
      collection_copy = @collection.dup

      # Use C extension for alternating filling
      result = TypeBalancer::AlternatingFiller.fill(
        collection_copy,
        empty_positions,
        primary_items,
        secondary_items
      )

      # Update collection if we got a valid result
      @collection = result if result.is_a?(Array)
    end

    def fill_remaining_gaps(items_arrays)
      # Add all new items to the order list before filling gaps
      items_arrays.each { |items| @item_order.concat(items) }

      # Find empty positions
      empty_positions = find_empty_positions
      return if empty_positions.empty?

      # Create a copy of the collection for filling
      collection_copy = @collection.dup

      # Use C extension for sequential filling
      result = TypeBalancer::SequentialFiller.fill(
        collection_copy,
        empty_positions,
        items_arrays
      )

      # Update collection if we got a valid result
      @collection = result if result.is_a?(Array)
    end

    def result
      # If no items have been placed, return an empty array
      return [] if @item_order.empty?

      # Get all non-nil items from the collection
      non_nil_items = @collection.compact

      # Return empty array if no items were successfully placed
      return [] if non_nil_items.empty?

      # Return all items that were successfully placed, in their original order
      @item_order.select { |item| non_nil_items.include?(item) }
    end

    private

    def find_empty_positions
      # Find all positions that are nil and within bounds
      (0...@size).select { |i| @collection[i].nil? }
    end
  end
end
