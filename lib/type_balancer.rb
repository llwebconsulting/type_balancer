# frozen_string_literal: true

require 'type_balancer/version'
require 'type_balancer/ruby/calculator'

begin
  require 'type_balancer/native/native'
rescue LoadError
  warn 'Native extension not available, falling back to pure Ruby implementation'
end

module TypeBalancer
  class Error < StandardError; end
  class ConfigurationError < Error; end

  class Configuration
    attr_accessor :use_c_extensions

    def initialize
      @use_c_extensions = true # Default to C extensions for best performance
    end
  end

  class << self
    attr_reader :implementation_mode

    def configure
      yield self if block_given?
    end

    def implementation_mode=(mode)
      mode = mode.to_sym
      unless %i[hybrid pure_ruby pure_c native_struct].include?(mode)
        raise ArgumentError,
              "Invalid implementation mode: #{mode}. Must be :hybrid, :pure_ruby, :pure_c, or :native_struct"
      end

      if %i[pure_c native_struct].include?(mode)
        begin
          require 'type_balancer/native'
        rescue LoadError => e
          raise LoadError, "C implementation (#{mode}) not available: #{e.message}"
        end
      end

      @implementation_mode = mode
    end

    def calculate_positions(total_count:, ratio:, available_items: nil)
      case implementation_mode
      when :pure_c
        require 'type_balancer/native' unless defined?(TypeBalancer::Native)
        Native.calculate_positions(
          total_count,
          ratio,
          available_items
        )
      when :native_struct
        require 'type_balancer/native' unless defined?(TypeBalancer::Native)
        Native.calculate_positions_native(
          total_count,
          ratio,
          available_items
        )
      when :pure_ruby
        Ruby::Calculator.calculate_positions(
          total_count: total_count,
          ratio: ratio,
          available_items: available_items
        )
      else # :hybrid (default)
        begin
          require 'type_balancer/native'
          Native.calculate_positions(
            total_count,
            ratio,
            available_items
          )
        rescue LoadError
          Ruby::Calculator.calculate_positions(
            total_count: total_count,
            ratio: ratio,
            available_items: available_items
          )
        end
      end
    rescue ArgumentError => e
      raise ValidationError, e.message
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def use_c_extensions?
      configuration.use_c_extensions && implementation_mode != :pure_ruby
    end
  end

  # Set default implementation mode
  @implementation_mode = :hybrid

  # Now load Ruby implementations
  require_relative 'type_balancer/distribution_calculator'
  require_relative 'type_balancer/ordered_collection_manager'
  require_relative 'type_balancer/gap_fillers_ext'
  require_relative 'type_balancer/alternating_filler'
  require_relative 'type_balancer/sequential_filler'
  require_relative 'type_balancer/balancer'
  require_relative 'type_balancer/distributor'

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

  # Error raised when input validation fails
  class ValidationError < StandardError; end

  # Error raised when memory allocation fails
  class MemoryError < StandardError; end

  # Your code goes here...
end
