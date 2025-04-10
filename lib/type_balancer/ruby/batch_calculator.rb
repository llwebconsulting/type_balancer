# frozen_string_literal: true

module TypeBalancer
  module Ruby
    # Batch processing implementation for position calculations
    class BatchCalculator
      # Represents a batch of position calculations
      class PositionBatch
        attr_reader :total_count, :available_count, :ratio

        def initialize(total_count:, available_count:, ratio:)
          @total_count = total_count
          @available_count = available_count
          @ratio = ratio
        end

        def valid?
          total_count.positive? &&
            available_count.positive? &&
            ratio.positive? &&
            ratio <= 1.0 &&
            available_count <= total_count
        end
      end

      class << self
        # Calculate positions for a batch of inputs
        # @param batch [PositionBatch] The batch configuration
        # @param iterations [Integer] Number of times to calculate (for benchmarking)
        # @return [Array<Integer>, nil] Array of calculated positions or nil if invalid
        def calculate_positions_batch(batch, iterations = 1)
          return nil unless batch.valid?

          # Calculate target count
          target_count = calculate_target_count(batch)
          return [] if target_count.zero?
          return [0] if target_count == 1

          # Calculate spacing
          spacing = batch.total_count.to_f / target_count

          # Process all iterations (for benchmarking)
          positions = nil
          iterations.times do
            positions = Array.new(target_count) do |i|
              # Calculate ideal position
              ideal_pos = i * spacing

              # Round to nearest integer and ensure bounds
              pos = ideal_pos.round
              pos.clamp(0, batch.total_count - 1)
            end
          end

          positions
        end

        private

        def calculate_target_count(batch)
          target = (batch.total_count * batch.ratio).ceil
          [target, batch.available_count].min
        end
      end
    end
  end
end
