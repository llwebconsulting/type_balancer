# frozen_string_literal: true

require 'type_balancer/version'
require 'type_balancer/calculator'
require_relative 'type_balancer/balancer'
require_relative 'type_balancer/ratio_calculator'
require_relative 'type_balancer/batch_processing'
require 'type_balancer/position_calculator'

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
    Distributor.calculate_target_positions(
      total_count: total_count,
      ratio: ratio,
      available_positions: available_items
    )
  end

  def self.balance(items, type_field: :type, type_order: nil)
    # Input validation
    raise EmptyCollectionError, 'Collection cannot be empty' if items.empty?

    # Extract and validate types
    types = extract_types(items, type_field)
    raise Error, "Invalid type field: #{type_field}" if types.empty?

    # Group items by type
    items.group_by { |item| extract_type(item, type_field) }

    # Initialize balancer with type order if provided
    balancer = Balancer.new(types, type_order: type_order)

    # Balance items
    balancer.call(items)
  end

  def self.extract_types(items, type_field)
    items.map { |item| extract_type(item, type_field) }.uniq
  end

  def self.extract_type(item, type_field)
    if item.is_a?(Hash)
      item[type_field] || item[type_field.to_s]
    else
      item.public_send(type_field)
    end
  rescue NoMethodError
    nil
  end
end
