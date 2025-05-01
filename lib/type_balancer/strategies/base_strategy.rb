# frozen_string_literal: true

module TypeBalancer
  module Strategies
    # Base class for all balancing strategies
    class BaseStrategy
      def initialize(items:, type_field:, types: nil, type_order: nil)
        @items = items
        @type_field = type_field
        @types = types
        @type_order = type_order
      end

      # Interface method that all strategies must implement
      def balance
        raise NotImplementedError, 'Strategies must implement #balance'
      end

      protected

      def validate_items!
        @items.each do |item|
          raise ArgumentError, 'All items must have a type field' unless item.key?(@type_field)
          raise ArgumentError, 'Type values cannot be empty' if item[@type_field].to_s.strip.empty?
        end
      end

      def extract_types
        types = @items.map { |item| item[@type_field].to_s }.uniq
        if @type_order
          # First include ordered types that exist in the items
          ordered = @type_order & types
          # Then append any remaining types that weren't in the order
          ordered + (types - @type_order)
        else
          # Use default order if no custom order provided
          DEFAULT_TYPE_ORDER.select { |type| types.include?(type) } + (types - DEFAULT_TYPE_ORDER)
        end
      end

      def group_items_by_type
        # First, create a hash to store items by type while preserving order
        type_queues = {}
        @types.each { |type| type_queues[type] = [] }

        # Add items to their respective queues in order
        @items.each do |item|
          type = item[@type_field].to_s
          type_queues[type] << item if type_queues.key?(type)
        end

        type_queues
      end

      DEFAULT_TYPE_ORDER = %w[video image strip article].freeze
    end
  end
end
