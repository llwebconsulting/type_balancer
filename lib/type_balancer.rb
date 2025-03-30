# frozen_string_literal: true

require_relative 'type_balancer/version'
require_relative 'type_balancer/distribution_calculator'
require_relative 'type_balancer/ordered_collection_manager'
require_relative 'type_balancer/gap_fillers/base'
require_relative 'type_balancer/gap_fillers/alternating'
require_relative 'type_balancer/gap_fillers/sequential'
require_relative 'type_balancer/balancer'

module TypeBalancer
  class Error < StandardError; end

  def self.balance(collection, type_field: :type, type_order: nil)
    Balancer.new(collection, type_field: type_field, types: type_order).call
  end

  # Your code goes here...
end
