# frozen_string_literal: true

require 'type_balancer/version'
require_relative 'type_balancer/balancer'
require_relative 'type_balancer/ratio_calculator'
require_relative 'type_balancer/batch_processing'
require_relative 'type_balancer/position_calculator'
require_relative 'type_balancer/type_extractor'
require_relative 'type_balancer/type_extractor_registry'
require_relative 'type_balancer/strategies/base_strategy'
require_relative 'type_balancer/strategies/sliding_window_strategy'
require_relative 'type_balancer/strategy_factory'

module TypeBalancer
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class ValidationError < Error; end
  class EmptyCollectionError < Error; end
  class InvalidTypeError < Error; end

  # Register default strategies
  StrategyFactory.register(:sliding_window, Strategies::SlidingWindowStrategy)
  StrategyFactory.default_strategy = :sliding_window

  # Load Ruby implementations
  require_relative 'type_balancer/distribution_calculator'
  require_relative 'type_balancer/ordered_collection_manager'
  require_relative 'type_balancer/type_extractor'
  require_relative 'type_balancer/type_extractor_registry'
  require_relative 'type_balancer/ratio_calculator'
  require_relative 'type_balancer/position_calculator'
  require_relative 'type_balancer/distributor'
  require_relative 'type_balancer/sequential_filler'
  require_relative 'type_balancer/alternating_filler'
  require_relative 'type_balancer/balancer'
  require_relative 'type_balancer/batch_processing'
  require_relative 'type_balancer/calculator'

  def self.calculate_positions(total_count:, ratio:, available_items: nil)
    PositionCalculator.calculate_positions(
      total_count: total_count,
      ratio: ratio,
      available_items: available_items
    )
  end

  # rubocop:disable Metrics/ParameterLists
  def self.balance(items, type_field: :type, type_order: nil, strategy: nil, window_size: nil, **strategy_options)
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

    # Merge window_size into strategy_options if provided
    strategy_options = strategy_options.merge(window_size: window_size) if window_size

    # Create calculator with strategy options
    calculator = Calculator.new(
      items,
      type_field: type_field,
      types: type_order || types,
      type_order: type_order,
      strategy: strategy,
      **strategy_options
    )

    # Balance items
    calculator.call
  end
  # rubocop:enable Metrics/ParameterLists

  # Backward compatibility methods
  def self.extract_types(items, type_field)
    TypeExtractorRegistry.get(type_field).extract_types(items)
  rescue Error
    # For backward compatibility, return array with nil for inaccessible type fields
    [nil]
  end
end
