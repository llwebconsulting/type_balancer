# frozen_string_literal: true

module TypeBalancer
  class Distributor
    def self.calculate_target_positions(total_count, available_items, target_ratio)
      # This method is implemented in C and will be available after loading the extension
      # The implementation is in ext/type_balancer/distributor.c
    end
  end
end
