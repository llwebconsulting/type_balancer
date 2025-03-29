# frozen_string_literal: true

module TypeBalancer
  module GapFillers
    # A gap filling strategy that fills empty positions sequentially from
    # each array of items. It processes one type at a time, placing items
    # in the first available gap before moving to the next type.
    class Sequential < Base
      def initialize(collection, items_arrays)
        super(collection)
        @items_arrays = items_arrays.compact.reject(&:empty?)
      end

      def fill_gaps(positions)
        return @collection if positions.empty? || @items_arrays.empty?

        item_queues = @items_arrays.map(&:dup)
        current_queue_index = 0

        positions.each do |pos|
          next unless @collection[pos].nil?

          @collection[pos] = fill_from_available_queues(item_queues, current_queue_index)
          current_queue_index = next_queue_index(current_queue_index, item_queues)
        end

        @collection
      end

      private

      def fill_from_available_queues(queues, start_index)
        return nil if queues.empty?

        queues.size.times do |offset|
          queue_index = (start_index + offset) % queues.size
          next if queues[queue_index].empty?

          return queues[queue_index].shift
        end
        nil
      end

      def next_queue_index(current_index, queues)
        return 0 if queues.empty?

        queues.size.times do |offset|
          candidate_index = (current_index + 1 + offset) % queues.size
          return candidate_index unless queues[candidate_index].empty?
        end
        current_index
      end
    end
  end
end
