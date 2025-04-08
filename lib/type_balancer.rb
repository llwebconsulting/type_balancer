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
      # Check if C extensions are actually available
      return false unless configuration.use_c_extensions

      begin
        require 'type_balancer/distributor'
        require 'type_balancer/balancer'
        true
      rescue LoadError
        false
      end
    end
  end
end

# Now load Ruby implementations
require_relative 'type_balancer/distribution_calculator'
require_relative 'type_balancer/ordered_collection_manager'
require_relative 'type_balancer/gap_fillers_ext'
require_relative 'type_balancer/alternating_filler'
require_relative 'type_balancer/sequential_filler'
require_relative 'type_balancer/balancer'
require_relative 'type_balancer/distributor'

module TypeBalancer
  # C extension-based balancer
  class CBalancer
    def initialize(collection, type_field, types = nil)
      @collection = collection
      @type_field = type_field
      @types = types || extract_types
    end

    def balance
      return [] if @collection.empty?

      # Group items by type
      items_by_type = @collection.group_by { |item| get_type(item) }

      # Calculate target positions for each type
      total_count = @collection.size
      positions_by_type = {}

      # Calculate ratios based on type order
      ratios = case @types.size
               when 0 then []
               when 1 then [1.0]
               when 2 then [0.6, 0.4]
               else
                 first_ratio = 0.35
                 remaining_ratio = (1.0 - first_ratio) / (@types.size - 1)
                 [first_ratio] + Array.new(@types.size - 1, remaining_ratio)
               end

      # Calculate positions for each type
      @types.each_with_index do |type, index|
        items = items_by_type[type] || []
        ratio = ratios[index]
        # Calculate positions relative to total count
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

  def self.balance(collection, type_field: :type, type_order: nil)
    if use_c_extensions?
      CBalancer.new(collection, type_field, type_order).balance
    else
      Balancer.new(collection, type_field: type_field, types: type_order).call
    end
  end

  def self.extract_types(collection, type_field)
    collection.map do |item|
      if item.respond_to?(type_field)
        item.send(type_field)
      elsif item.respond_to?(:[])
        item[type_field] || item[type_field.to_s]
      else
        raise Error, "Cannot access type field '#{type_field}' on item #{item}"
      end
    end.uniq
  end

  # Your code goes here...
end
