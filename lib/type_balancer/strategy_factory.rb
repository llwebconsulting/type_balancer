# frozen_string_literal: true

module TypeBalancer
  # Factory for creating and managing balancing strategies
  class StrategyFactory
    class << self
      def create(strategy_name = nil, **)
        strategy_name ||= default_strategy
        strategy_class = find_strategy(strategy_name)

        raise ArgumentError, "Unknown strategy: #{strategy_name}" unless strategy_class

        strategy_class.new(**)
      end

      def register(name, strategy_class)
        strategies[name.to_sym] = strategy_class
      end

      def default_strategy=(name)
        raise ArgumentError, "Unknown strategy: #{name}" unless strategies.key?(name.to_sym)

        @default_strategy = name.to_sym
      end

      def default_strategy
        @default_strategy ||= :sliding_window
      end

      private

      def strategies
        @strategies ||= {}
      end

      def find_strategy(name)
        strategies[name.to_sym]
      end
    end
  end
end
