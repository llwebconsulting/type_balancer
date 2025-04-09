# frozen_string_literal: true

require 'type_balancer'

module TypeBalancer
  module C
    class Calculator
      class << self
        def calculate_positions(total_count:, ratio:, available_items: nil)
          # Input validation (we still do this in Ruby for consistency)
          raise ArgumentError, 'total_count must be positive' unless total_count.positive?
          raise ArgumentError, 'ratio must be between 0 and 1' unless ratio > 0 && ratio <= 1

          # This is the hybrid version that still uses Ruby/C boundary crossing
          Native.calculate_positions(
            total_count: total_count,
            ratio: ratio,
            available_items: available_items
          )
        end

        def calculate_positions_native(total_count:, ratio:, available_items: nil)
          # This is the pure C version that avoids Ruby/C boundary crossing
          # It directly allocates and returns C memory without converting to Ruby objects
          Native.calculate_positions_native(
            total_count: total_count,
            ratio: ratio,
            available_items: available_items
          )
        end
      end
    end
  end
end
