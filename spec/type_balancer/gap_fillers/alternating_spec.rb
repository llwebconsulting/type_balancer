# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::GapFillers::Alternating do
  subject(:filler) { described_class.new(collection, primary_items, secondary_items) }

  let(:collection) { Array.new(6) }
  let(:primary_items) { %w[P1 P2 P3] }
  let(:secondary_items) { %w[S1 S2 S3] }

  describe '#fill_gaps' do
    let(:positions) { (0...collection.size).to_a }

    context 'with available items' do
      it 'alternates between primary and secondary items' do
        result = filler.fill_gaps(positions)
        expect(result).to eq(%w[P1 S1 P2 S2 P3 S3])
      end

      it 'handles when primary items run out' do
        filler = described_class.new(collection, [], secondary_items)
        result = filler.fill_gaps(positions)
        expect(result).to eq(['S1', 'S2', 'S3', nil, nil, nil])
      end

      it 'handles when secondary items run out' do
        filler = described_class.new(collection, primary_items, [])
        result = filler.fill_gaps(positions)
        expect(result).to eq(['P1', 'P2', 'P3', nil, nil, nil])
      end
    end

    context 'with partially filled positions' do
      let(:collection) { ['X1', nil, 'X2', nil, 'X3', nil] }
      let(:positions) { [1, 3, 5] }

      it 'fills only nil positions alternating between primary and secondary items' do
        result = filler.fill_gaps(positions)
        expect(result).to eq(%w[X1 P1 X2 S1 X3 P2])
      end
    end

    context 'when positions array is empty' do
      it 'returns the collection unchanged' do
        expect(filler.fill_gaps([])).to eq(collection)
      end
    end

    context 'when some positions are already filled' do
      let(:collection) { ['X1', nil, 'X2', nil, 'X3', nil] }
      let(:positions) { [0, 1, 2, 3, 4, 5] }

      it 'only fills nil positions' do
        result = filler.fill_gaps(positions)
        expect(result).to eq(%w[X1 P1 X2 S1 X3 P2])
      end
    end
  end
end
