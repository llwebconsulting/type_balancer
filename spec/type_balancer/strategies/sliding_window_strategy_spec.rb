# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Strategies::SlidingWindowStrategy do
  let(:items) do
    [
      { type: 'video', id: 1 },
      { type: 'image', id: 2 },
      { type: 'article', id: 3 },
      { type: 'video', id: 4 },
      { type: 'image', id: 5 },
      { type: 'article', id: 6 }
    ]
  end

  let(:window_size) { 3 }
  let(:batch_size) { 1000 }
  let(:strategy) do
    described_class.new(items: items, type_field: :type, window_size: window_size, batch_size: batch_size)
  end

  describe '#initialize' do
    it 'sets instance variables' do
      expect(strategy.instance_variable_get(:@items)).to eq(items)
      expect(strategy.instance_variable_get(:@type_field)).to eq(:type)
      expect(strategy.instance_variable_get(:@window_size)).to eq(window_size)
      expect(strategy.instance_variable_get(:@batch_size)).to eq(batch_size)
    end

    it 'uses default batch size when not specified' do
      strategy = described_class.new(items: items, type_field: :type)
      expect(strategy.instance_variable_get(:@batch_size)).to eq(described_class::DEFAULT_BATCH_SIZE)
    end

    it 'accepts custom types' do
      custom_types = %w[video image]
      strategy = described_class.new(items: items, type_field: :type, types: custom_types)
      expect(strategy.instance_variable_get(:@types)).to eq(custom_types)
    end
  end

  describe '#balance' do
    context 'with small collection (single batch)' do
      it 'processes all items in one batch' do
        result = strategy.balance
        expect(result.size).to eq(items.size)
        expect(result).to match_array(items)
      end

      it 'maintains type distribution' do
        result = strategy.balance
        types = result.map { |item| item[:type] }
        expect(types.count('video')).to eq(2)
        expect(types.count('image')).to eq(2)
        expect(types.count('article')).to eq(2)
      end
    end

    context 'with large collection (multiple batches)' do
      let(:large_items) do
        types = %w[video image article]
        300.times.map do |i|
          { type: types[i % 3], id: i }
        end
      end

      let(:batch_size) { 100 }
      let(:strategy) do
        described_class.new(items: large_items, type_field: :type, window_size: window_size, batch_size: batch_size)
      end

      it 'processes all items across multiple batches' do
        result = strategy.balance
        expect(result.size).to eq(large_items.size)
        expect(result).to match_array(large_items)
      end

      it 'maintains type distribution across batches' do
        result = strategy.balance
        types = result.map { |item| item[:type] }

        # Each type should appear roughly equally
        type_counts = types.tally
        expected_count = large_items.size / 3
        type_counts.each_value do |count|
          expect(count).to be_within(1).of(expected_count)
        end
      end

      it 'maintains relative positioning across batch boundaries' do
        result = strategy.balance

        # Check distribution in each batch
        (0...result.size).step(batch_size) do |start|
          batch = result[start...[start + batch_size, result.size].min]
          types = batch.map { |item| item[:type] }

          # Each type should be distributed throughout the batch
          %w[video image article].each do |type|
            type_positions = types.each_with_index.select { |t, _| t == type }.map(&:last)
            next if type_positions.empty?

            # Check that items of the same type are not all clumped together
            gaps = type_positions.each_cons(2).map { |a, b| b - a }
            expect(gaps.max).to be < batch.size / 2
          end
        end
      end
    end

    context 'with empty collection' do
      let(:items) { [] }

      it 'returns an empty array' do
        expect(strategy.balance).to eq([])
      end
    end

    context 'with single type' do
      let(:items) do
        [
          { type: 'video', id: 1 },
          { type: 'video', id: 2 },
          { type: 'video', id: 3 }
        ]
      end

      it 'returns items in original order' do
        expect(strategy.balance).to eq(items)
      end
    end

    context 'with multiple types' do
      let(:window_size) { 3 }

      it 'balances items within windows' do
        result = strategy.balance
        first_window = result.first(3)

        # Check that first window has representation from each type
        types_in_window = first_window.map { |i| i[:type] }.uniq
        expect(types_in_window.size).to be >= 2
      end

      it 'maintains approximate ratios' do
        result = strategy.balance
        type_counts = result.group_by { |i| i[:type] }.transform_values(&:count)

        # Each type should have 2 items (equal distribution in test data)
        expect(type_counts['video']).to eq(2)
        expect(type_counts['image']).to eq(2)
        expect(type_counts['article']).to eq(2)
      end

      it 'includes all items exactly once' do
        result = strategy.balance
        expect(result.size).to eq(items.size)
        expect(result.map { |i| i[:id] }.sort).to eq([1, 2, 3, 4, 5, 6])
      end

      it 'maintains local diversity in each window' do
        result = strategy.balance
        windows = result.each_slice(window_size).to_a

        windows.each do |window|
          types = window.map { |i| i[:type] }.uniq
          # Each complete window should have at least 2 different types
          expect(types.size).to be >= 2 if window.size >= 2
        end
      end
    end

    context 'with uneven distribution' do
      let(:items) do
        [
          { type: 'video', id: 1 },
          { type: 'video', id: 2 },
          { type: 'video', id: 3 },
          { type: 'image', id: 4 },
          { type: 'article', id: 5 }
        ]
      end

      it 'handles uneven type distribution' do
        result = strategy.balance
        type_counts = result.group_by { |i| i[:type] }.transform_values(&:count)

        expect(type_counts['video']).to eq(3)
        expect(type_counts['image']).to eq(1)
        expect(type_counts['article']).to eq(1)
      end

      it 'spreads dominant type across windows' do
        result = strategy.balance
        video_positions = result.each_with_index.select { |item, _| item[:type] == 'video' }.map(&:last)

        # Videos should not all be consecutive
        consecutive_videos = video_positions.each_cons(2).count { |a, b| b == a + 1 }
        expect(consecutive_videos).to be < video_positions.size - 1
      end
    end

    context 'with window size larger than item count' do
      let(:window_size) { 10 }

      it 'handles window size adjustment correctly' do
        result = strategy.balance
        expect(result.size).to eq(items.size)
        expect(result.map { |i| i[:id] }.sort).to eq([1, 2, 3, 4, 5, 6])
      end
    end

    context 'with custom type field' do
      let(:items) do
        [
          { category: 'video', id: 1 },
          { category: 'image', id: 2 },
          { category: 'video', id: 3 }
        ]
      end

      let(:strategy) { described_class.new(items: items, type_field: :category, window_size: window_size) }

      it 'uses custom type field for balancing' do
        result = strategy.balance
        expect(result.size).to eq(items.size)
        expect(result.map { |i| i[:category] }).to include('video', 'image')
      end
    end
  end

  describe 'performance' do
    let(:large_items) do
      types = %w[video image article]
      100_000.times.map do |i|
        { type: types[i % 3], id: i }
      end
    end

    let(:strategy) do
      described_class.new(items: large_items, type_field: :type, window_size: window_size, batch_size: batch_size)
    end

    it 'handles very large collections efficiently' do
      start_time = Time.now
      result = strategy.balance
      end_time = Time.now
      duration = end_time - start_time

      # Should process 100k items efficiently
      expect(duration).to be < 1.0 # Should complete in under 1 second
      expect(result.size).to eq(large_items.size)

      # Verify type distribution
      types = result.map { |item| item[:type] }
      type_counts = types.tally
      expected_count = large_items.size / 3

      type_counts.each_value do |count|
        expect(count).to be_within(1).of(expected_count)
      end
    end
  end
end
