module TypeBalancer
  class PositionCalculator
    def self.calculate_positions(target_count, total_count, available_positions = nil)
      # Input validation
      return nil if target_count.nil? || total_count.nil?
      return nil if target_count < 0 || total_count < 0
      return nil if target_count > total_count
      return [] if target_count.zero?
      return nil if total_count.zero?

      # Handle available positions
      if available_positions
        return nil if available_positions.empty?
        return nil if available_positions.any? { |pos| pos >= total_count }
        return available_positions.sort if target_count >= available_positions.size

        if target_count == 1
          # For single target, prefer earlier positions
          return [available_positions.first]
        end

        # For multiple targets, ensure even distribution
        sorted_positions = available_positions.sort
        return [sorted_positions.first, sorted_positions.last] if target_count == 2

        indices = []
        step = (sorted_positions.size - 1).to_f / (target_count - 1)
        target_count.times do |i|
          index = (i * step).round
          indices << sorted_positions[index]
        end
        return indices
      end

      # Handle regular distribution without available positions
      return [0] if target_count == 1

      return [0, [total_count - 1, 1].min] if target_count == 2

      # For more than 2 positions, ensure even distribution
      positions = []
      step = (total_count - 1).to_f / (target_count - 1)
      target_count.times do |i|
        pos = (i * step).round
        positions << pos
      end
      positions
    end
  end
end
