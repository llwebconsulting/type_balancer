# frozen_string_literal: true

module TypeBalancer
  # Manages an ordered collection of items, providing methods to place items
  # at specific positions and fill gaps using different strategies.
  # This class acts as a facade for the gap filling functionality.
  class OrderedCollectionManager
    def initialize(size)
      @collection = Array.new(size)
      @original_positions = {} # Track original positions for ordering
      @has_explicit_ordering = false # Flag to indicate if we should use original order
    end

    def place_at_positions(items, positions)
      # Reset original positions for this batch of items
      items.each_with_index do |item, i|
        @original_positions[item] = i
      end

      positions.each_with_index do |pos, i|
        break if i >= items.size

        @collection[pos] = items[i]
      end

      @has_explicit_ordering = true
    end

    alias place_items_at_positions place_at_positions

    def fill_gaps_alternating(primary_items, secondary_items)
      @has_explicit_ordering = false  # Gap filling should maintain position order
      filler = GapFillers::Alternating.new(@collection, primary_items, secondary_items)
      @collection = filler.fill_gaps(find_empty_positions)
    end

    def fill_remaining_gaps(items_arrays)
      @has_explicit_ordering = false  # Gap filling should maintain position order
      filler = GapFillers::Sequential.new(@collection, items_arrays)
      @collection = filler.fill_gaps(find_empty_positions)
    end

    def result
      items = @collection.compact
      if @has_explicit_ordering
        # Sort by original position when items were explicitly placed
        items.sort_by { |item| @original_positions[item] || Float::INFINITY }
      else
        # Return in position order for gap-filled items
        items
      end
    end

    private

    def find_empty_positions
      (0...@collection.size).reject { |i| @collection[i] }
    end
  end
end
