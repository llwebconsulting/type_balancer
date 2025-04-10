# frozen_string_literal: true

require 'type_balancer/version'
require 'type_balancer/calculator'
require_relative 'type_balancer/balancer'
require_relative 'type_balancer/ratio_calculator'
require_relative 'type_balancer/batch_processing'

module TypeBalancer
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class ValidationError < Error; end
  class EmptyCollectionError < Error; end
  class InvalidTypeError < Error; end

  # Load Ruby implementations
  require_relative 'type_balancer/distribution_calculator'
  require_relative 'type_balancer/ordered_collection_manager'
  require_relative 'type_balancer/alternating_filler'
  require_relative 'type_balancer/sequential_filler'
  require_relative 'type_balancer/distributor'

  def self.calculate_positions(total_count:, ratio:, available_items: nil)
    PositionCalculator.calculate_positions(
      total_count: total_count,
      ratio: ratio,
      available_items: available_items
    )
  end

  def self.balance(collection, types:, batch_size: 10, type_order: nil, type_field: :type)
    raise EmptyCollectionError, 'Collection cannot be empty' if collection.empty?
    raise ArgumentError, 'Types cannot be empty' if types.empty?
    raise ArgumentError, 'Batch size must be positive' unless batch_size.positive?

    # Group items by type using the specified type_field
    items_by_type = collection.group_by do |item|
      if item.respond_to?(type_field)
        item.send(type_field)
      elsif item.respond_to?(:[])
        item[type_field] || item[type_field.to_s]
      else
        raise Error, "Cannot access type field '#{type_field}' on item #{item}"
      end
    end

    # Create balancer and balance items
    balancer = Balancer.new(types, batch_size, type_order: type_order)
    balancer.call(items_by_type)
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
end
