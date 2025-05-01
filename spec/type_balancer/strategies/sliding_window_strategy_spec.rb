# frozen_string_literal: true

require 'spec_helper'
require 'type_balancer/strategies'
require 'type_balancer/strategies/base_strategy'
require 'type_balancer/strategies/sliding_window_strategy'

RSpec.describe TypeBalancer::Strategies::SlidingWindowStrategy do
  let(:items) do
    [
      { type: 'video', id: 1 },
      { type: 'video', id: 2 },
      { type: 'image', id: 3 },
      { type: 'image', id: 4 },
      { type: 'image', id: 5 },
      { type: 'article', id: 6 }
    ]
  end

  describe '#initialize' do
    it 'sets window size' do
      strategy = described_class.new(items: items, type_field: :type, window_size: 15)
      expect(strategy.instance_variable_get(:@window_size)).to eq(15)
    end

    it 'uses default window size when not specified' do
      strategy = described_class.new(items: items, type_field: :type)
      expect(strategy.instance_variable_get(:@window_size)).to eq(10)
    end
  end

  describe '#balance' do
    subject(:strategy) { described_class.new(items: items, type_field: :type, window_size: window_size) }

    context 'with empty items' do
      let(:window_size) { 10 }
      let(:items) { [] }

      it 'returns empty array' do
        expect(strategy.balance).to eq([])
      end
    end

    context 'with single type' do
      let(:window_size) { 10 }
      let(:items) { [{ type: 'video', id: 1 }, { type: 'video', id: 2 }] }

      it 'returns items in original order' do
        expect(strategy.balance.map { |i| i[:id] }).to eq([1, 2])
      end
    end

    context 'with multiple types' do
      let(:window_size) { 3 }

      it 'balances items within windows' do
        result = strategy.balance
        first_window = result.first(3)

        # Check that first window has representation from each type
        types_in_window = first_window.map { |i| i[:type] }.uniq
        expect(types_in_window).to include('video', 'image')
      end

      it 'maintains approximate ratios' do
        result = strategy.balance.first(6)
        type_counts = result.group_by { |i| i[:type] }.transform_values(&:count)

        # With 2 videos, 3 images, 1 article in 6 items
        # We expect roughly 2:3:1 ratio
        expect(type_counts['video']).to be >= 1
        expect(type_counts['image']).to be >= 2
        expect(type_counts['article']).to be >= 1
      end

      it 'includes all items exactly once' do
        result = strategy.balance
        expect(result.size).to eq(items.size)
        expect(result.map { |i| i[:id] }.uniq.size).to eq(items.size)
      end
    end

    context 'with window size larger than item count' do
      let(:window_size) { 20 }

      it 'handles window size adjustment correctly' do
        result = strategy.balance
        expect(result.size).to eq(items.size)
      end
    end
  end

  describe 'private methods' do
    let(:strategy) { described_class.new(items: items, type_field: :type, window_size: 3) }
    let(:type_queues) { strategy.send(:group_items_by_type) }
    let(:type_ratios) { { 'video' => 0.33, 'image' => 0.5, 'article' => 0.17 } }

    describe '#calculate_window_targets' do
      it 'calculates correct target counts for window' do
        targets = strategy.send(:calculate_window_targets, type_ratios, 3)
        expect(targets.values.sum).to eq(3)
        expect(targets.values.all? { |v| v >= 0 }).to be true
      end
    end

    describe '#find_next_type' do
      let(:used_items) { Set.new }
      let(:current_counts) { { 'video' => 0, 'image' => 0, 'article' => 0 } }
      let(:target_counts) { { 'video' => 1, 'image' => 1, 'article' => 1 } }

      it 'selects type based on current distribution' do
        next_type = strategy.send(:find_next_type, type_ratios, current_counts, target_counts, type_queues, used_items)
        expect(type_ratios.keys).to include(next_type)
      end

      it 'returns nil when all targets are met' do
        full_counts = { 'video' => 1, 'image' => 1, 'article' => 1 }
        next_type = strategy.send(:find_next_type, type_ratios, full_counts, target_counts, type_queues, used_items)
        expect(next_type).to be_nil
      end
    end
  end
end
