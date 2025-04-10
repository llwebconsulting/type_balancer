# frozen_string_literal: true

module TypeBalancer
  # Pure Ruby implementation of the balancing algorithm
  class PureRubyCalculator
    def initialize(items, type_field:, types: nil)
      @items = items
      @type_field = type_field
      @types = types || extract_types
    end

    def call
      return [] if @items.empty?

      items_by_type = @types.map { |type| items_of_type(type) }
      target_positions = calculate_target_positions(items_by_type)
      place_items_at_positions(items_by_type, target_positions)
    end

    private

    def items_of_type(type)
      @items.select { |item| item[@type_field].to_s == type.to_s }
    end

    def calculate_target_positions(items_by_type)
      total_count = @items.size
      target_positions = []

      items_by_type.each_with_index do |_items, index|
        ratio = if items_by_type.size == 1
                  1.0
                elsif index.zero?
                  0.4
                else
                  0.3
                end

        target_count = (total_count * ratio).round
        positions = calculate_spacing(total_count, target_count)
        target_positions << positions
      end

      target_positions
    end

    def calculate_spacing(total_count, target_count)
      return [] if target_count <= 0 || total_count <= 0

      base_spacing = calculate_base_spacing(total_count, target_count)
      spacing = adjust_spacing_for_edge_cases(base_spacing, total_count, target_count)
      generate_positions(spacing, total_count, target_count)
    end

    def calculate_base_spacing(total_count, target_count)
      return 0 if target_count <= 0

      (total_count.to_f / target_count).floor
    end

    def adjust_spacing_for_edge_cases(spacing, total_count, target_count)
      return 1 if spacing <= 0
      return total_count if target_count <= 1

      spacing
    end

    def generate_positions(spacing, total_count, target_count)
      positions = []
      current_pos = 0

      target_count.times do
        break if current_pos >= total_count

        positions << current_pos
        current_pos += spacing
      end

      positions
    end

    def place_items_at_positions(items_by_type, target_positions)
      result = Array.new(@items.size)
      place_items_at_target_positions(items_by_type, target_positions, result)
      fill_remaining_positions(items_by_type, target_positions, result)
      result.compact
    end

    def place_items_at_target_positions(items_by_type, target_positions, result)
      items_by_type.each_with_index do |items, type_index|
        positions = target_positions[type_index]
        next if positions.empty?

        items.each_with_index do |item, item_index|
          break if item_index >= positions.size

          result[positions[item_index]] = item
        end
      end
    end

    def fill_remaining_positions(items_by_type, target_positions, result)
      remaining_items = collect_remaining_items(items_by_type, target_positions)
      fill_empty_slots(result, remaining_items)
    end

    def collect_remaining_items(items_by_type, target_positions)
      items_by_type.flat_map.with_index do |items, type_index|
        positions = target_positions[type_index]
        items[positions.size..]
      end.compact
    end

    def fill_empty_slots(result, remaining_items)
      result.each_with_index do |item, index|
        next unless item.nil?
        break if remaining_items.empty?

        result[index] = remaining_items.shift
      end
    end
  end
end
