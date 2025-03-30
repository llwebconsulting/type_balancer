# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::GapFillers::Alternating do
  subject(:filler) { described_class.new(collection, primary_items, secondary_items) }

  let(:collection) { Array.new(6) }

  describe '#fill_gaps' do
    let(:positions) { (0...collection.size).to_a }
    let(:primary_items) { %w[A1 A2 A3] }
    let(:secondary_items) { %w[B1 B2 B3] }

    context 'with available items' do
      it 'alternates between primary and secondary items' do
        result = filler.fill_gaps(positions)
        expect(result).to eq(%w[A1 B1 A2 B2 A3 B3])
      end

      it 'handles when primary items run out' do
        filler = described_class.new(collection, [], secondary_items)
        result = filler.fill_gaps(positions)
        expect(result).to eq(['B1', 'B2', 'B3', nil, nil, nil])
      end

      it 'handles when secondary items run out' do
        filler = described_class.new(collection, primary_items, [])
        result = filler.fill_gaps(positions)
        expect(result).to eq(['A1', 'A2', 'A3', nil, nil, nil])
      end
    end

    context 'with partially filled positions' do
      let(:collection) { ['X1', nil, 'X2', nil, 'X3', nil] }
      let(:positions) { [1, 3, 5] }

      it 'fills only nil positions alternating between primary and secondary items' do
        result = filler.fill_gaps(positions)
        expect(result).to eq(%w[X1 A1 X2 B1 X3 A2])
      end
    end
  end
end
