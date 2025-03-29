# frozen_string_literal: true

module TypeBalancer
  module GapFillers
    # Base class for gap filling strategies.
    # Gap fillers are responsible for placing items into a sequence of positions,
    # where some positions may already be filled and others are nil (gaps).
    class Base
      def initialize(collection)
        @collection = collection
      end

      def fill_gaps(positions)
        raise NotImplementedError, "#{self.class} must implement #fill_gaps"
      end
    end
  end
end
