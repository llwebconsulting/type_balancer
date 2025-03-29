# frozen_string_literal: true

module TypeBalancer
  module GapFillers
    # A gap filling strategy that alternates between primary and secondary items
    # when filling empty positions in a sequence. When one type runs out,
    # it continues with available items from other types.
    class Alternating < Base
      def initialize(collection, primary_items, secondary_items)
        super(collection)
        @primary_items = primary_items
        @secondary_items = secondary_items
      end

      def fill_gaps(positions)
        return @collection if positions.empty?

        primary_items_queue = @primary_items.dup
        secondary_items_queue = @secondary_items.dup
        use_primary = true

        positions.each do |pos|
          next unless @collection[pos].nil?

          @collection[pos] = if use_primary
                               fill_with_primary_or_secondary(primary_items_queue, secondary_items_queue)
                             else
                               fill_with_secondary_or_primary(secondary_items_queue, primary_items_queue)
                             end
          use_primary = !use_primary
        end

        @collection
      end

      private

      def fill_with_primary_or_secondary(primary_queue, secondary_queue)
        return fill_with_available(secondary_queue) if primary_queue.empty?

        primary_queue.shift
      end

      def fill_with_secondary_or_primary(secondary_queue, primary_queue)
        return fill_with_available(primary_queue) if secondary_queue.empty?

        secondary_queue.shift
      end

      def fill_with_available(queue)
        queue.shift || nil
      end
    end
  end
end
