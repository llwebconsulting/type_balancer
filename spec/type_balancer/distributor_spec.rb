# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Distributor do
  describe '.calculate_target_positions' do
    context 'when validating input' do
      it 'returns empty array for non-positive total count' do
        expect(described_class.calculate_target_positions(0, 1, 0.5)).to eq([])
        expect(described_class.calculate_target_positions(-1, 1, 0.5)).to eq([])
      end

      it 'returns empty array for non-positive available count' do
        expect(described_class.calculate_target_positions(10, 0, 0.5)).to eq([])
        expect(described_class.calculate_target_positions(10, -1, 0.5)).to eq([])
      end

      it 'returns empty array for invalid ratio' do
        expect(described_class.calculate_target_positions(10, 5, 0)).to eq([])
        expect(described_class.calculate_target_positions(10, 5, -0.1)).to eq([])
        expect(described_class.calculate_target_positions(10, 5, 1.1)).to eq([])
      end

      it 'returns empty array when available count exceeds total count' do
        expect(described_class.calculate_target_positions(5, 6, 0.5)).to eq([])
      end
    end

    context 'when handling special cases' do
      it 'returns empty array when target count is zero' do
        expect(described_class.calculate_target_positions(5, 0, 0.1)).to eq([])
      end

      it 'returns [0] when target count is 1' do
        expect(described_class.calculate_target_positions(5, 1, 0.2)).to eq([0])
      end
    end

    context 'when calculating positions' do
      it 'calculates positions for 20% distribution' do
        positions = described_class.calculate_target_positions(10, 5, 0.2)
        expect(positions).to eq([0, 5])
      end

      it 'handles when available items are less than target' do
        positions = described_class.calculate_target_positions(10, 1, 0.2)
        expect(positions).to eq([0])
      end

      it 'returns empty array for zero available items' do
        positions = described_class.calculate_target_positions(10, 0, 0.2)
        expect(positions).to be_empty
      end

      it 'handles small collections' do
        positions = described_class.calculate_target_positions(3, 2, 0.4)
        expect(positions).to eq([0, 2])
      end

      it 'handles uneven spacing correctly' do
        positions = described_class.calculate_target_positions(7, 2, 0.3)
        expect(positions).to eq([0, 4])
      end

      it 'respects maximum available items' do
        positions = described_class.calculate_target_positions(10, 2, 0.5)
        expect(positions).to eq([0, 5])
      end

      it 'handles a collection of size 1' do
        positions = described_class.calculate_target_positions(1, 1, 0.5)
        expect(positions).to eq([0])
      end

      it 'handles zero total count' do
        positions = described_class.calculate_target_positions(0, 5, 0.2)
        expect(positions).to be_empty
      end

      it 'handles 100% ratio' do
        positions = described_class.calculate_target_positions(5, 5, 1.0)
        expect(positions).to eq([0, 1, 2, 3, 4])
      end

      it 'handles very small ratio' do
        positions = described_class.calculate_target_positions(10, 10, 0.01)
        expect(positions).to eq([0])
      end

      it 'calculates evenly spaced positions' do
        result = described_class.calculate_target_positions(10, 3, 0.3)
        expect(result).to eq([0, 3, 7])
      end

      it 'ensures positions are unique and sorted' do
        result = described_class.calculate_target_positions(5, 3, 0.6)
        expect(result).to eq(result.uniq.sort)
      end

      it 'never exceeds total count' do
        result = described_class.calculate_target_positions(10, 4, 0.4)
        expect(result.max).to be < 10
      end

      it 'never returns negative positions' do
        result = described_class.calculate_target_positions(10, 4, 0.4)
        expect(result.min).to be >= 0
      end
    end
  end
end
