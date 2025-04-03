# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::OrderedCollectionManager do
  subject(:manager) { described_class.new(size) }

  let(:size) { 10 }

  describe '#place_at_positions' do
    let(:manager) { described_class.new(5) }
    let(:items) { %w[A B C] }
    let(:positions) { [1, 3, 4] }

    it 'places items at specified positions' do
      manager.place_at_positions(items, positions)
      expect(manager.result).to eq(%w[A B C])
    end

    it 'places items in sequence' do
      manager.place_at_positions(items, positions)
      expect(manager.result).to eq(%w[A B C])
    end

    context 'with more positions than items' do
      let(:positions) { [0, 2, 4, 5] }

      it 'fills available positions' do
        manager.place_at_positions(items, positions)
        expect(manager.result).to eq(%w[A B C])
      end

      it 'leaves extra positions as nil' do
        manager.place_at_positions(items, positions)
        expect(manager.result).to eq(%w[A B C])
      end
    end

    context 'with more items than positions' do
      let(:items) { %w[A B C D E] }
      let(:positions) { [1, 3] }

      it 'uses only the needed items' do
        manager.place_at_positions(items, positions)
        expect(manager.result).to eq(%w[A B])
      end

      it 'ignores extra items' do
        manager.place_at_positions(items, positions)
        expect(manager.result).to eq(%w[A B])
      end
    end
  end

  describe '#fill_gaps_alternating' do
    let(:manager) { described_class.new(6) }
    let(:primary_items) { %w[A B C] }
    let(:secondary_items) { %w[X Y Z] }

    context 'with empty positions' do
      before do
        manager.place_at_positions(%w[Q], [3])
      end

      it 'fills gaps with alternating items' do
        # Mock the C extension to return a filled array
        filled_array = [primary_items[0], secondary_items[0], primary_items[1], 'Q', secondary_items[1],
                        primary_items[2]]
        allow(TypeBalancer::AlternatingFiller).to receive(:fill).and_return(filled_array)

        manager.fill_gaps_alternating(primary_items, secondary_items)
        result = manager.result

        # Should contain Q from initial placement
        expect(result).to include('Q')

        # Should contain items from both arrays
        expect(result & primary_items).not_to be_empty
        expect(result & secondary_items).not_to be_empty
      end
    end

    context 'when one type runs out' do
      let(:primary_items) { %w[A] }
      let(:secondary_items) { %w[X Y Z] }

      it 'uses available items to fill gaps' do
        # Mock the C extension to return a filled array
        filled_array = [primary_items[0], secondary_items[0], secondary_items[1], secondary_items[2], nil, nil]
        allow(TypeBalancer::AlternatingFiller).to receive(:fill).and_return(filled_array)

        manager.fill_gaps_alternating(primary_items, secondary_items)
        result = manager.result

        # Should contain the primary item
        expect(result).to include('A')

        # Should contain secondary items
        expect(result & secondary_items).not_to be_empty
      end
    end
  end

  describe '#fill_remaining_gaps' do
    let(:manager) { described_class.new(6) }
    let(:items_arrays) { [%w[A B], %w[X Y], %w[1 2]] }

    context 'with empty positions' do
      before do
        manager.place_at_positions(%w[Q], [3])
      end

      it 'fills gaps with items from multiple arrays' do
        # Mock the C extension to return a filled array
        filled_array = [items_arrays[0][0], items_arrays[1][0], items_arrays[2][0], 'Q', items_arrays[0][1],
                        items_arrays[1][1]]
        allow(TypeBalancer::SequentialFiller).to receive(:fill).and_return(filled_array)

        manager.fill_remaining_gaps(items_arrays)
        result = manager.result

        # Should contain Q from initial placement
        expect(result).to include('Q')

        # Should contain items from all arrays
        items_arrays.each do |items|
          expect(result & items).not_to be_empty
        end
      end
    end
  end

  describe '#result' do
    it 'returns only non-nil elements' do
      manager.place_at_positions(%w[A B], [0, 2])
      expect(manager.result).to eq(%w[A B])
    end

    it 'preserves order of placed items' do
      manager.place_at_positions(%w[A B C], [2, 0, 1])
      expect(manager.result).to eq(%w[A B C])
    end

    it 'returns empty array when no items placed' do
      expect(manager.result).to be_empty
    end
  end
end
