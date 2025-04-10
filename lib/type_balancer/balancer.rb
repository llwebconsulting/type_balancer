# frozen_string_literal: true

module TypeBalancer
  # Main class responsible for balancing items in a collection based on their types.
  # It uses a distribution calculator to determine optimal positions for each type
  # and a gap filler strategy to place items in the final sequence.
  class Balancer
    BATCH_SIZE = 500 # Process items in batches of 500 for better performance

    def initialize(collection, type_field: :type, types: nil, distribution_calculator: nil)
      @collection = collection
      @type_field = type_field
      @types = types || extract_types
      @distribution_calculator = distribution_calculator || Distributor
    end

    def call
      return [] if @collection.empty?

      if @collection.size <= BATCH_SIZE
        process_single_batch(@collection)
      else
        process_multiple_batches
      end
    end

    private

    def process_single_batch(items)
      # Group items by type
      items_by_type = items.group_by { |item| get_type(item) }

      # Calculate ratios based on type order and counts
      ratios = calculate_ratios(items_by_type)

      # Calculate positions for each type
      positions_by_type = calculate_positions_by_type(items_by_type, ratios, items.size)

      # Map items to their balanced positions
      balanced_items = place_items_in_positions(items_by_type, positions_by_type, items.size)

      # Fill any gaps with remaining items
      fill_gaps(balanced_items, items)
    end

    def process_multiple_batches
      result = []
      @collection.each_slice(BATCH_SIZE) do |batch|
        result.concat(process_single_batch(batch))
      end
      result
    end

    def calculate_positions_by_type(items_by_type, ratios, total_count)
      positions_by_type = {}

      @types.each_with_index do |type, index|
        items = items_by_type[type] || []
        ratio = ratios[index]
        positions = @distribution_calculator.calculate_target_positions(total_count, items.size, ratio)
        positions_by_type[type] = positions
      end

      positions_by_type
    end

    def place_items_in_positions(items_by_type, positions_by_type, total_count)
      balanced_items = Array.new(total_count)

      @types.each do |type|
        items = items_by_type[type] || []
        positions = positions_by_type[type] || []

        items.each_with_index do |item, index|
          pos = positions[index]
          next unless pos && pos < total_count && balanced_items[pos].nil?

          balanced_items[pos] = item
        end
      end

      balanced_items
    end

    def fill_gaps(balanced_items, original_items)
      # Fill any gaps with remaining items
      remaining_items = original_items.reject { |item| balanced_items.include?(item) }
      empty_positions = balanced_items.each_index.select { |i| balanced_items[i].nil? }

      empty_positions.each_with_index do |pos, idx|
        break unless idx < remaining_items.size

        balanced_items[pos] = remaining_items[idx]
      end

      balanced_items.compact
    end

    def calculate_ratios(_items_by_type)
      case @types.size
      when 1
        [1.0]
      when 2
        [0.6, 0.4]
      else
        # First type gets 0.4, rest split remaining 0.6 evenly
        remaining = (0.6 / (@types.size - 1).to_f).round(6)
        [0.4] + Array.new(@types.size - 1, remaining)
      end
    end

    def get_type(item)
      if item.respond_to?(@type_field)
        item.send(@type_field)
      elsif item.respond_to?(:[])
        item[@type_field] || item[@type_field.to_s]
      else
        raise Error, "Cannot access type field '#{@type_field}' on item #{item}"
      end
    end

    def extract_types
      TypeBalancer.extract_types(@collection, @type_field)
    end
  end
end
