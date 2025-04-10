# frozen_string_literal: true

module TypeBalancer
  # Main class responsible for balancing items in a collection based on their types.
  # It uses a distribution calculator to determine optimal positions for each type
  # and a gap filler strategy to place items in the final sequence.
  class Balancer
    def initialize(collection, type_field: :type, types: nil)
      @collection = collection
      @type_field = type_field
      @types = types || extract_types
    end

    def call
      return [] if @collection.empty?

      # Group items by type
      items_by_type = @collection.group_by { |item| get_type(item) }

      # Calculate target positions for each type
      total_count = @collection.size
      positions_by_type = {}

      # Calculate ratios based on type order and counts
      ratios = calculate_ratios(items_by_type)

      # Calculate positions for each type
      @types.each_with_index do |type, index|
        items = items_by_type[type] || []
        ratio = ratios[index]
        positions = Distributor.calculate_target_positions(total_count, items.size, ratio)
        positions_by_type[type] = positions
      end

      # Map items to their balanced positions
      balanced_items = Array.new(total_count)

      # Process types in order
      @types.each do |type|
        items = items_by_type[type] || []
        positions = positions_by_type[type] || []

        items.each_with_index do |item, index|
          pos = positions[index]
          next unless pos && pos < total_count && balanced_items[pos].nil?

          balanced_items[pos] = item
        end
      end

      # Fill any gaps with remaining items
      remaining_items = @collection.reject { |item| balanced_items.include?(item) }
      remaining_items.each do |item|
        empty_pos = balanced_items.index(nil)
        break unless empty_pos

        balanced_items[empty_pos] = item
      end

      balanced_items.compact
    end

    private

    def calculate_ratios(items_by_type)
      @collection.size.to_f
      @types.map { |type| (items_by_type[type] || []).size }

      case @types.size
      when 0
        []
      when 1
        [1.0]
      when 2
        # For two types, use their relative proportions
        [0.6, 0.4]
      else
        # For three or more types, use the same ratios as C implementation
        first_ratio = 0.35
        remaining_ratio = (1.0 - first_ratio) / (@types.size - 1)
        [first_ratio] + Array.new(@types.size - 1, remaining_ratio)
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
      # Get unique types in the order they appear in the collection
      types = @collection.map { |item| get_type(item) }.uniq
      # Sort types to ensure consistent order: video, image, article
      default_order = %w[video image article]
      types.sort_by { |type| default_order.index(type) || types.size }
    end
  end
end
