# frozen_string_literal: true

module TypeBalancer
  # Ruby interface for the AlternatingFiller C extension
  class AlternatingFiller
    def initialize(collection, primary_items, secondary_items)
      @collection = collection
      @primary_items = primary_items
      @secondary_items = secondary_items
    end

    def self.fill(collection, positions, primary_items, secondary_items)
      # This method is implemented in C
      # See ext/type_balancer/alternating_filler.c
    end

    def fill_gaps(positions)
      # This method is implemented in C
      # See ext/type_balancer/alternating_filler.c
    end
  end
end
