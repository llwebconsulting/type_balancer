# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::RatioCalculator do
  describe '.calculate_ratios' do
    subject(:ratios) { described_class.calculate_ratios(types, items_by_type) }

    context 'with single type' do
      let(:types) { ['video'] }
      let(:items_by_type) { { 'video' => [1, 2, 3] } }

      it 'returns full ratio for single type' do
        expect(ratios).to eq({ 'video' => 1.0 })
      end
    end

    context 'with multiple types' do
      let(:types) { %w[video image strip] }
      let(:items_by_type) do
        {
          'video' => [1, 2, 3, 4],  # 4 items (40%)
          'image' => [1, 2, 3],     # 3 items (30%)
          'strip' => [1, 2, 3]      # 3 items (30%)
        }
      end

      it 'calculates ratios based on item counts' do
        expect(ratios.values.sum).to be_within(0.0001).of(1.0)
        expect(ratios['video']).to be > ratios['image']
        expect(ratios['image']).to eq(ratios['strip'])
      end

      it 'ensures minimum representation for each type' do
        min_ratio = 0.1
        ratios.each_value do |ratio|
          expect(ratio).to be >= min_ratio
        end
      end
    end

    context 'with missing types' do
      let(:types) { %w[video image strip] }
      let(:items_by_type) do
        {
          'video' => [1, 2, 3],
          'image' => []
        }
      end

      it 'handles missing types gracefully' do
        expect(ratios.keys).to match_array(types)
        expect(ratios.values.sum).to be_within(0.0001).of(1.0)
      end

      it 'assigns minimum ratio to empty types' do
        expect(ratios['image']).to be_within(0.0001).of(0.1)
        expect(ratios['strip']).to be_within(0.0001).of(0.1)
      end
    end

    context 'with uneven distributions' do
      let(:types) { %w[video image] }
      let(:items_by_type) do
        {
          'video' => [1] * 90,  # 90 items
          'image' => [1] * 10   # 10 items
        }
      end

      it 'maintains relative proportions while ensuring minimum ratios' do
        expect(ratios['video']).to be > ratios['image']
        expect(ratios['image']).to be >= 0.1
        expect(ratios.values.sum).to be_within(0.0001).of(1.0)
      end
    end
  end
end
