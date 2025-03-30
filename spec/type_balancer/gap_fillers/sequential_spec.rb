# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::GapFillers::Sequential do
  subject(:filler) { described_class.new(collection, items_arrays) }

  let(:collection) { Array.new(10) }
  let(:items_arrays) { [%w[A1 A2 A3], %w[B1 B2 B3], %w[C1 C2 C3]] }

  describe '#fill_gaps' do
    let(:positions) { (0...collection.size).to_a }

    context 'with available items' do
      it 'fills gaps sequentially from each array' do
        result = filler.fill_gaps(positions)
        expect(result).to eq(['A1', 'B1', 'C1', 'A2', 'B2', 'C2', 'A3', 'B3', 'C3', nil])
      end

      it 'handles when some arrays are empty' do
        items_arrays = [%w[A1 A2], [], %w[C1 C2]]
        filler = described_class.new(collection, items_arrays)
        result = filler.fill_gaps(positions)
        expect(result).to eq(['A1', 'C1', 'A2', 'C2', nil, nil, nil, nil, nil, nil])
      end

      it 'handles when all arrays are empty' do
        filler = described_class.new(collection, [[], [], []])
        result = filler.fill_gaps(positions)
        expect(result).to eq([nil] * 10)
      end
    end

    context 'when positions array is empty' do
      it 'returns the collection unchanged' do
        expect(filler.fill_gaps([])).to eq(collection)
      end
    end

    context 'when some positions are already filled' do
      let(:collection) { ['X1', nil, 'X2', nil, 'X3', nil, nil, nil, nil, nil] }

      it 'only fills nil positions' do
        result = filler.fill_gaps(positions)
        expect(result).to eq(%w[X1 A1 X2 B1 X3 C1 A2 B2 C2 A3])
      end
    end

    context 'when all queues become empty during filling' do
      let(:items_arrays) { [%w[A1], %w[B1], %w[C1]] }

      it 'fills remaining positions with nil' do
        result = filler.fill_gaps(positions)
        expect(result).to eq(['A1', 'B1', 'C1', nil, nil, nil, nil, nil, nil, nil])
      end
    end

    context 'when items_arrays is empty' do
      let(:items_arrays) { [] }

      it 'returns the collection unchanged' do
        expect(filler.fill_gaps(positions)).to eq(collection)
      end
    end

    context 'when all queues are empty but not exhausted' do
      let(:items_arrays) { [[], [], []] }

      it 'returns collection with nil values' do
        result = filler.fill_gaps(positions)
        expect(result).to eq([nil] * 10)
      end
    end

    context 'when all queues become empty and next_queue_index is called' do
      let(:items_arrays) { [%w[A1], [], %w[C1]] }

      it 'handles empty queues correctly' do
        result = filler.fill_gaps(positions)
        expect(result).to eq(['A1', 'C1', nil, nil, nil, nil, nil, nil, nil, nil])
      end
    end

    context 'when all queues are empty and next_queue_index is called' do
      let(:items_arrays) { [[], [], []] }

      it 'returns the current index' do
        result = filler.fill_gaps(positions)
        expect(result).to eq([nil] * 10)
      end
    end

    context 'with empty collection' do
      it 'fills sequentially from each array' do
        result = filler.fill_gaps((0..5).to_a)
        expect(result).to eq(['A1', 'B1', 'C1', 'A2', 'B2', 'C2', nil, nil, nil, nil])
      end
    end

    context 'with existing items' do
      let(:collection) { [nil, 'X', nil, nil, 'Y', nil, nil, nil, nil, nil] }

      it 'fills only nil positions sequentially from each array' do
        result = filler.fill_gaps([0, 2, 3, 5])
        expect(result).to eq(['A1', 'X', 'B1', 'C1', 'Y', 'A2', nil, nil, nil, nil])
      end

      it 'handles arrays of different sizes' do
        arrays = [%w[A1 A2], %w[B1], %w[C1]]
        filler = described_class.new(collection, arrays)
        result = filler.fill_gaps([0, 2, 3, 5])
        expect(result).to eq(['A1', 'X', 'B1', 'C1', 'Y', 'A2', nil, nil, nil, nil])
      end

      it 'handles single array' do
        filler = described_class.new(collection, [%w[A1 A2 A3]])
        result = filler.fill_gaps([0, 2, 3, 5])
        expect(result).to eq(['A1', 'X', 'A2', 'A3', 'Y', nil, nil, nil, nil, nil])
      end
    end

    context 'with empty arrays' do
      it 'returns original collection when all arrays are empty' do
        filler = described_class.new(collection, [[], [], []])
        result = filler.fill_gaps([0, 1, 2])
        expect(result).to eq([nil] * 10)
      end

      it 'skips empty arrays' do
        arrays = [[], %w[B1 B2], []]
        filler = described_class.new(collection, arrays)
        result = filler.fill_gaps([0, 1])
        expect(result[0..1]).to eq(%w[B1 B2])
      end

      it 'handles empty array list' do
        filler = described_class.new(collection, [])
        result = filler.fill_gaps([0, 1, 2])
        expect(result).to eq([nil] * 10)
      end
    end

    context 'with nil arrays' do
      it 'handles nil arrays in the list' do
        arrays = [%w[A1 A2], nil, %w[C1 C2]]
        filler = described_class.new(collection, arrays)
        result = filler.fill_gaps([0, 1, 2, 3])
        expect(result[0..3]).to eq(%w[A1 C1 A2 C2])
      end

      it 'handles all nil arrays' do
        filler = described_class.new(collection, [nil, nil, nil])
        result = filler.fill_gaps([0, 1, 2])
        expect(result).to eq([nil] * 10)
      end
    end

    context 'with empty queues' do
      let(:items_arrays) { [] }

      it 'returns nil when fill_from_available_queues is called with empty queues' do
        result = filler.fill_gaps([0])
        expect(result[0]).to be_nil
      end

      it 'returns 0 when next_queue_index is called with empty queues' do
        result = filler.fill_gaps([0, 1])
        expect(result).to eq([nil] * 10)
      end
    end
  end
end
