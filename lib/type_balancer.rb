# frozen_string_literal: true

require 'type_balancer/version'
require 'type_balancer/calculator'

module TypeBalancer
  class Error < StandardError; end
  class ConfigurationError < Error; end

  # Load Ruby implementations
  require_relative 'type_balancer/distribution_calculator'
  require_relative 'type_balancer/ordered_collection_manager'
  require_relative 'type_balancer/gap_fillers_ext'
  require_relative 'type_balancer/alternating_filler'
  require_relative 'type_balancer/sequential_filler'
  require_relative 'type_balancer/balancer'
  require_relative 'type_balancer/distributor'

  def self.calculate_positions(total_count:, ratio:, available_items: nil)
    PositionCalculator.calculate_positions(
      total_count: total_count,
      ratio: ratio,
      available_items: available_items
    )
  end

  def self.balance(collection, type_field: :type, type_order: nil)
    Balancer.new(collection, type_field: type_field, types: type_order).call
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

  # Error raised when input validation fails
  class ValidationError < StandardError; end
end
