# frozen_string_literal: true

require 'type_balancer/version'
require 'type_balancer/calculator'
require_relative 'type_balancer/balancer'
require_relative 'type_balancer/ratio_calculator'
require_relative 'type_balancer/batch_processing'
require 'type_balancer/position_calculator'
require_relative 'type_balancer/type_extractor'
require_relative 'type_balancer/type_extractor_registry'

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

    # Use centralized extractor
    extractor = TypeExtractorRegistry.get(type_field)
    begin
      types = extractor.extract_types(items)
      raise Error, "Invalid type field: #{type_field}" if types.empty?
    rescue Error => e
      raise Error, "Cannot access type field '#{type_field}': #{e.message}"
    end

    # Initialize balancer with type order and type field
    balancer = Balancer.new(types, type_field: type_field, type_order: type_order)

    # Balance items
    balancer.call(items)
  end

  # Backward compatibility methods
  def self.extract_types(items, type_field)
    TypeExtractorRegistry.get(type_field).extract_types(items)
  rescue Error => e
    # For backward compatibility, return array with nil for inaccessible type fields
    [nil]
  end
end
