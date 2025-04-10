# frozen_string_literal: true

require 'type_balancer/sequential_filler'

RSpec.describe TypeBalancer::SequentialFiller do
  let(:collection) { [1, 2, 3, 4, 5] }
  let(:items_arrays) { [[2, 3, 4, 5]] }
  let(:filler) { described_class.new(collection, items_arrays) }

  describe '.fill' do
    it 'creates a new instance and calls fill_gaps' do
      positions = [1, nil, nil]
      expect(described_class.fill(collection, positions, items_arrays)).to eq([1, 2, 3])
    end
  end

  describe '#fill_gaps' do
    context 'when positions array is empty' do
      it 'returns an empty array' do
        expect(filler.fill_gaps([])).to eq([])
      end

      it 'returns empty array for nil positions' do
        expect(filler.fill_gaps(nil)).to eq([])
      end
    end

    context 'when positions have no gaps' do
      it 'returns the original positions unchanged' do
        positions = [1, 2, 3]
        expect(filler.fill_gaps(positions)).to eq([1, 2, 3])
      end
    end

    context 'when positions have gaps' do
      it 'fills gaps sequentially with remaining items' do
        positions = [1, nil, 3, nil, nil]
        expect(filler.fill_gaps(positions)).to eq([1, 2, 3, 3, 4])
      end

      it 'preserves original positions' do
        positions = [nil, 2, nil, 4]
        expect(filler.fill_gaps(positions)).to eq([2, 2, 3, 4])
      end

      it 'handles case when there are more gaps than remaining items' do
        positions = [1, nil, nil, nil, nil]
        items_arrays = [[2, 3]]
        filler = described_class.new(collection, items_arrays)
        expect(filler.fill_gaps(positions)).to eq([1, 2, 3, nil, nil])
      end

      it 'handles case when remaining items become empty mid-filling' do
        positions = [nil, 2, nil, nil, nil]
        items_arrays = [[3]] # Only one item to fill gaps
        filler = described_class.new(collection, items_arrays)
        expect(filler.fill_gaps(positions)).to eq([3, 2, nil, nil, nil])
      end

      it 'skips non-nil positions while filling' do
        positions = [1, nil, 2, nil, 3]
        items_arrays = [[4, 5]]
        filler = described_class.new(collection, items_arrays)
        result = filler.fill_gaps(positions)
        expect(result).to eq([1, 4, 2, 5, 3])
        # Verifies that non-nil positions (1, 2, 3) were skipped and preserved
      end
    end
  end
end
