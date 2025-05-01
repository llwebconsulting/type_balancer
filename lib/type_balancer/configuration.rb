# frozen_string_literal: true

module TypeBalancer
  # Configuration class to handle all balancing options
  class Configuration
    attr_accessor :type_field, :type_order, :strategy, :window_size, :batch_size, :types
    attr_reader :strategy_options

    def initialize(options = {})
      @type_field = options.fetch(:type_field, :type)
      @type_order = options[:type_order]
      @strategy = options[:strategy]
      @window_size = options[:window_size]
      @batch_size = options[:batch_size]
      @types = options[:types]
      @strategy_options = extract_strategy_options(options)
    end

    def merge_window_size
      return strategy_options unless window_size

      strategy_options.merge(window_size: window_size)
    end

    private

    def extract_strategy_options(options)
      options.reject { |key, _| %i[type_field type_order strategy window_size types].include?(key) }
    end
  end
end
