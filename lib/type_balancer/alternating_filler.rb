# frozen_string_literal: true

module TypeBalancer
  # Fills gaps by alternating between primary and secondary items
  class AlternatingFiller
    def initialize(collection, primary_items, secondary_items)
      @collection = collection
      @primary_items = primary_items
      @secondary_items = secondary_items
    end

    def self.fill(collection, positions, primary_items, secondary_items)
      new(collection, primary_items, secondary_items).fill_gaps(positions)
    end

    def fill_gaps(positions)
      return positions if positions.compact.size == positions.size
      return [] if positions.empty?

      filled_positions = positions.dup
      use_primary = true

      positions.each_with_index do |pos, idx|
        next unless pos.nil?

        item = select_next_item(use_primary)
        break unless item

        filled_positions[idx] = item
        use_primary = !use_primary
      end

      filled_positions
    end

    private

    def select_next_item(use_primary)
      if (use_primary || @secondary_items.empty?) && !@primary_items.empty?
        @primary_items.shift
      elsif !@secondary_items.empty?
        @secondary_items.shift
      end
    end
  end
end
