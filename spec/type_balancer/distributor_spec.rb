# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Distributor do
  describe '.calculate_target_positions' do
    subject(:positions) do
      described_class.calculate_target_positions(total_count, available_count, ratio, available_items)
    end

    let(:available_items) { nil }

    context 'with invalid inputs' do
      it 'returns empty array for negative total count' do
        expect(described_class.calculate_target_positions(-1, 1, 0.5)).to eq([])
      end

      it 'returns empty array for negative available count' do
        expect(described_class.calculate_target_positions(10, -1, 0.5)).to eq([])
      end

      it 'returns empty array for invalid ratio' do
        expect(described_class.calculate_target_positions(10, 5, 1.5)).to eq([])
      end

      it 'returns empty array when available count exceeds total' do
        expect(described_class.calculate_target_positions(5, 10, 0.5)).to eq([])
      end
    end

    context 'with single item' do
      let(:total_count) { 10 }
      let(:available_count) { 1 }
      let(:ratio) { 0.1 }

      it 'places the item at the start' do
        expect(positions).to eq([0])
      end

      context 'with available positions' do
        let(:available_items) { [5] }

        it 'uses the specified position' do
          expect(positions).to eq([5])
        end
      end
    end

    context 'with multiple items' do
      let(:total_count) { 10 }
      let(:available_count) { 3 }
      let(:ratio) { 0.3 }

      it 'distributes items evenly' do
        expect(positions.size).to eq(3)
        expect(positions).to eq([0, 3, 7])
      end

      context 'with available positions' do
        let(:available_items) { [2, 4, 6, 8] }

        it 'distributes within available positions' do
          expect(positions.size).to eq(3)
          expect(positions).to eq([2, 6, 8])
        end
      end
    end

    context 'with edge cases' do
      it 'handles zero target count' do
        expect(described_class.calculate_target_positions(10, 5, 0)).to eq([])
      end

      it 'handles minimum ratio' do
        positions = described_class.calculate_target_positions(100, 1, 0.01)
        expect(positions.size).to eq(1)
      end

      it 'handles maximum ratio' do
        positions = described_class.calculate_target_positions(10, 10, 1.0)
        expect(positions.size).to eq(10)
        expect(positions).to eq((0..9).to_a)
      end
    end

    context 'with specific spacing requirements' do
      let(:total_count) { 100 }
      let(:available_count) { 5 }
      let(:ratio) { 0.05 }

      it 'maintains roughly equal spacing' do
        diffs = positions.each_cons(2).map { |a, b| b - a }
        avg_diff = diffs.sum.to_f / diffs.size
        expect(diffs).to all(be_within(2).of(avg_diff))
      end

      it 'Check that spacing between positions is relatively even' do
        diffs = positions.each_cons(2).map { |a, b| b - a }
        expect(diffs).to all(be_within(1).of(diffs.first))
      end
    end

    context 'with valid inputs' do
      let(:total_count) { 10 }
      let(:ratio) { 0.4 }
      let(:positions) { described_class.calculate_target_positions(total_count, 3, ratio, [2, 4, 6, 8]) }

      it 'returns positions with even spacing' do
        diffs = positions.each_cons(2).map { |a, b| b - a }
        expect(diffs).to all(be_within(1).of(diffs.first))
      end
    end
  end
end
