# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Distributor do
  describe '.calculate_target_positions' do
    subject(:positions) do
      described_class.calculate_target_positions(
        total_count: total_count,
        ratio: ratio,
        available_positions: available_positions
      )
    end

    let(:available_positions) { nil }
    let(:total_count) { 10 }
    let(:ratio) { 0.3 }

    context 'with invalid inputs' do
      it 'returns empty array for negative total count' do
        expect(described_class.calculate_target_positions(total_count: -1, ratio: 0.5)).to eq([])
      end

      it 'returns empty array for invalid ratio' do
        expect(described_class.calculate_target_positions(total_count: 10, ratio: 1.5)).to eq([])
      end
    end

    context 'with single item' do
      let(:total_count) { 10 }
      let(:ratio) { 0.1 }

      it 'places the item at the start' do
        expect(positions).to eq([0])
      end

      context 'with available positions' do
        let(:available_positions) { [5] }

        it 'uses the first available position' do
          expect(positions).to eq([5])
        end
      end
    end

    context 'with multiple items' do
      let(:total_count) { 10 }
      let(:ratio) { 0.3 }

      it 'distributes items evenly' do
        expect(positions.size).to eq(3)
        expect(positions).to eq([0, 5, 9])
      end

      context 'with available positions' do
        let(:available_positions) { [2, 4, 6, 8] }

        it 'distributes within available positions' do
          expect(positions.size).to eq(3)
          expect(positions).to eq([2, 4, 6])
        end
      end

      context 'with two available positions' do
        let(:available_positions) { [2, 8] }
        let(:ratio) { 0.2 }

        it 'uses first and last available positions' do
          expect(positions.size).to eq(2)
          expect(positions).to eq([2, 8])
        end
      end

      context 'with exact available positions' do
        let(:available_positions) { [2, 4, 6] }

        it 'takes all positions' do
          expect(positions.size).to eq(3)
          expect(positions).to eq([2, 4, 6])
        end
      end
    end

    context 'with edge cases' do
      it 'handles zero target count' do
        expect(described_class.calculate_target_positions(total_count: 10, ratio: 0)).to eq([])
      end

      it 'handles minimum ratio' do
        positions = described_class.calculate_target_positions(total_count: 100, ratio: 0.01)
        expect(positions.size).to eq(1)
      end

      it 'handles maximum ratio' do
        positions = described_class.calculate_target_positions(total_count: 10, ratio: 1.0)
        expect(positions.size).to eq(10)
        expect(positions).to eq((0..9).to_a)
      end
    end

    context 'with specific spacing requirements' do
      let(:total_count) { 100 }
      let(:ratio) { 0.05 }

      it 'maintains roughly equal spacing' do
        diffs = positions.each_cons(2).map { |a, b| b - a }
        avg_diff = diffs.sum.to_f / diffs.size
        expect(diffs).to all(be_within(2).of(avg_diff))
      end
    end

    context 'with three slots' do
      let(:total_count) { 3 }

      context 'with one item' do
        let(:ratio) { 0.34 }

        it 'places at start' do
          expect(positions).to eq([0])
        end
      end

      context 'with two items' do
        let(:ratio) { 0.67 }

        it 'places at start and middle' do
          expect(positions).to eq([0, 1])
        end
      end
    end
  end
end
