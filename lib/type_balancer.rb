# frozen_string_literal: true

require_relative 'type_balancer/version'

module TypeBalancer
  class Error < StandardError; end

  class Configuration
    attr_accessor :use_c_extensions

    def initialize
      @use_c_extensions = true # Default to C extensions for best performance
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end

    def use_c_extensions?
      configuration.use_c_extensions
    end
  end
end

require_relative 'type_balancer/distribution_calculator'
require_relative 'type_balancer/ordered_collection_manager'

# Load gap fillers C extension
require_relative 'type_balancer/gap_fillers_ext'

# Load Ruby interfaces for C extensions
require_relative 'type_balancer/alternating_filler'
require_relative 'type_balancer/sequential_filler'

require_relative 'type_balancer/balancer'

# Load C extensions
require 'type_balancer/distributor'

module TypeBalancer
  # C extension-based balancer
  class CBalancer
    def initialize(collection, type_field, types = nil)
      @collection = collection
      @type_field = type_field
      @types = types || TypeBalancer.send(:extract_types, collection, type_field)
    end

    def balance
      return [] if @collection.empty?

      # Group items by type
      items_by_type = {}
      @types.each { |type| items_by_type[type] = [] }

      @collection.each do |item|
        item_type = item[@type_field] || item[@type_field.to_s]
        items_by_type[item_type] << item if items_by_type.key?(item_type)
      end

      # Use C extensions for position calculations
      type_counts = items_by_type.values.map(&:size)
      total_count = @collection.size
      target_positions = []

      # Calculate positions for each type using the C extension
      type_counts.each do |count|
        positions = TypeBalancer::Distributor.calculate_target_positions(
          total_count,
          count,
          0.2
        )
        target_positions << positions
      end

      # Map items to their balanced positions
      ordered_items = Array.new(total_count)
      items_by_type.values.each_with_index do |items, idx|
        current_positions = target_positions[idx] || []
        items.each_with_index do |item, item_idx|
          break if item_idx >= current_positions.size

          ordered_items[current_positions[item_idx]] = item
        end
      end

      # Fill in any gaps
      ordered_items.compact
    end
  end

  def self.balance(collection, type_field: :type, type_order: nil)
    if use_c_extensions?
      CBalancer.new(collection, type_field, type_order || extract_types(collection, type_field)).balance
    else
      Balancer.new(collection, type_field: type_field, types: type_order).call
    end
  end

  def self.extract_types(collection, type_field)
    collection.map { |item| item[type_field] || item[type_field.to_s] }.uniq
  end

  # Your code goes here...
end
