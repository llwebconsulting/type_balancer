# frozen_string_literal: true

module TypeBalancer
  # Fills gaps in positions sequentially with remaining items
  class SequentialFiller
    def initialize(collection, items_arrays)
      @collection = collection
      @items_arrays = items_arrays
    end

    def self.fill(collection, positions, items_arrays)
      new(collection, items_arrays).fill_gaps(positions)
    end

    def fill_gaps(positions)
      return positions if positions.compact.size == positions.size
      return [] if positions.empty?

      remaining_items = @items_arrays.flatten
      filled_positions = positions.dup

      positions.each_with_index do |pos, idx|
        next unless pos.nil?
        break if remaining_items.empty?

        filled_positions[idx] = remaining_items.shift
      end

      filled_positions
    end
  end
end
