# frozen_string_literal: true

module TypeBalancer
  # Ruby interface for the SequentialFiller C extension
  class SequentialFiller
    def initialize(collection, items_arrays)
      @collection = collection
      @items_arrays = items_arrays
    end

    def self.fill(collection, positions, items_arrays)
      # This method is implemented in C
      # See ext/type_balancer/sequential_filler.c
    end

    def fill_gaps(positions)
      # This method is implemented in C
      # See ext/type_balancer/sequential_filler.c
    end
  end
end
