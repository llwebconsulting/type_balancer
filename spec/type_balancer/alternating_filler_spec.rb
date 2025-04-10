# frozen_string_literal: true

require 'type_balancer/alternating_filler'

RSpec.describe TypeBalancer::AlternatingFiller do
  let(:collection) { [1, 2, 3, 4, 5, 6] }
  let(:primary_items) { [2, 4] }
  let(:secondary_items) { [3, 5] }
  let(:filler) { described_class.new(collection, primary_items, secondary_items) }

  describe '.fill' do
    it 'creates a new instance and calls fill_gaps' do
      positions = [1, nil, nil]
      expect(described_class.fill(collection, positions, primary_items, secondary_items)).to eq([1, 2, 3])
    end
  end

  describe '#fill_gaps' do
    context 'when positions array is empty' do
      it 'returns an empty array' do
        expect(filler.fill_gaps([])).to eq([])
      end
    end

    context 'when positions have no gaps' do
      it 'returns the original positions unchanged' do
        positions = [1, 2, 3]
        expect(filler.fill_gaps(positions)).to eq([1, 2, 3])
      end
    end

    context 'when positions have gaps' do
      it 'fills gaps by alternating between primary and secondary items' do
        positions = [1, nil, nil, nil, nil]
        expect(filler.fill_gaps(positions)).to eq([1, 2, 3, 4, 5])
      end

      it 'preserves original positions' do
        positions = [nil, 2, nil, 4, nil]
        expect(filler.fill_gaps(positions)).to eq([2, 2, 3, 4, 4])
      end

      context 'when one array is empty' do
        it 'continues with available primary items when secondary is empty' do
          filler = described_class.new(collection, [2, 4], [])
          positions = [1, nil, nil]
          expect(filler.fill_gaps(positions)).to eq([1, 2, 4])
        end

        it 'continues with available secondary items when primary is empty' do
          filler = described_class.new(collection, [], [3, 5])
          positions = [1, nil, nil]
          expect(filler.fill_gaps(positions)).to eq([1, 3, 5])
        end
      end

      it 'handles case when there are more gaps than remaining items' do
        positions = [1, nil, nil, nil, nil]
        filler = described_class.new(collection, [2], [3])
        expect(filler.fill_gaps(positions)).to eq([1, 2, 3, nil, nil])
      end
    end
  end
end
