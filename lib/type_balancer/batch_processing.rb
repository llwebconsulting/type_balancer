# frozen_string_literal: true

module TypeBalancer
  class BatchProcessing
    def initialize(batch_size)
      @batch_size = batch_size
    end

    def create_batches(items_by_type, positions_by_type)
      total_items = items_by_type.values.sum(&:size)
      batches = []
      current_batch = []

      (0...total_items).each do |position|
        type = find_type_for_position(position, positions_by_type)
        current_batch << items_by_type[type].shift if type && !items_by_type[type].empty?

        if current_batch.size >= @batch_size || position == total_items - 1
          batches << current_batch unless current_batch.empty?
          current_batch = []
        end
      end

      batches
    end

    private

    def find_type_for_position(position, positions_by_type)
      positions_by_type.find do |_, positions|
        positions.include?(position)
      end&.first
    end
  end
end
