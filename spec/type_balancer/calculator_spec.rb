# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Calculator do
  let(:type_field) { :type }
  let(:items) { [] }
  let(:types) { nil }
  let(:calculator) { described_class.new(items, type_field: type_field, types: types) }

  describe '#initialize' do
    context 'with empty items' do
      it 'initializes without error' do
        expect { calculator }.not_to raise_error
      end
    end

    context 'with items and default type field' do
      let(:items) { [{ type: 'video' }, { type: 'image' }] }

      it 'extracts types from items' do
        expect(calculator.send(:extract_types)).to eq(%w[video image])
      end
    end

    context 'with custom type field' do
      let(:type_field) { :content_type }
      let(:items) { [{ content_type: 'video' }, { content_type: 'image' }] }

      it 'uses the custom field to extract types' do
        expect(calculator.send(:extract_types)).to eq(%w[video image])
      end
    end

    context 'with explicit types' do
      let(:items) { [{ type: 'video' }, { type: 'image' }] }
      let(:types) { %w[image video] }

      it 'uses the provided types' do
        expect(calculator.instance_variable_get(:@types)).to eq(types)
      end
    end

    it 'raises error when items is nil' do
      expect { described_class.new(nil) }.to raise_error(ArgumentError)
    end

    it 'raises error when type_field is nil' do
      expect { described_class.new(items, type_field: nil) }.to raise_error(ArgumentError)
    end

    it 'accepts strategy name' do
      calculator = described_class.new(items, strategy: :sliding_window)
      expect(calculator.instance_variable_get(:@strategy_name)).to eq(:sliding_window)
    end

    it 'accepts strategy options' do
      calculator = described_class.new(items, window_size: 20)
      expect(calculator.instance_variable_get(:@strategy_options)).to include(window_size: 20)
    end
  end

  describe '#call' do
    context 'with empty items' do
      it 'returns an empty array' do
        expect(calculator.call).to eq([])
      end
    end

    context 'with items' do
      let(:items) do
        [
          { type: 'video', id: 1 },
          { type: 'image', id: 2 },
          { type: 'video', id: 3 }
        ]
      end

      it 'delegates to strategy' do
        result = calculator.call
        expect(result).to be_an(Array)
        expect(result.size).to eq(items.size)
        expect(result.map { |i| i[:id] }.sort).to eq([1, 2, 3])
      end

      it 'uses custom strategy when specified' do
        # Create a test strategy that reverses items
        test_strategy = Class.new(TypeBalancer::Strategies::BaseStrategy) do
          def balance
            @items.reverse
          end
        end

        TypeBalancer::StrategyFactory.register(:test, test_strategy)
        calculator = described_class.new(items, strategy: :test)

        result = calculator.call
        expect(result).to eq(items.reverse)
      end

      it 'passes options to strategy' do
        calculator = described_class.new(items, window_size: 20)
        result = calculator.call
        expect(result).to be_an(Array)
        expect(result.size).to eq(items.size)
      end
    end

    context 'with custom type field' do
      let(:items) do
        [
          { media_type: 'video', id: 1 },
          { media_type: 'image', id: 2 }
        ]
      end

      it 'handles custom type field' do
        calculator = described_class.new(items, type_field: :media_type)
        result = calculator.call
        expect(result.size).to eq(items.size)
        expect(result.map { |i| i[:id] }.sort).to eq([1, 2])
      end
    end
  end

  describe '#extract_types' do
    context 'with custom type ordering' do
      let(:items) do
        [
          { type: 'article' },
          { type: 'video' },
          { type: 'image' },
          { type: 'custom' }
        ]
      end

      it 'orders types according to DEFAULT_TYPE_ORDER' do
        expect(calculator.send(:extract_types)).to eq(%w[video image article custom])
      end
    end
  end
end

RSpec.describe TypeBalancer::PositionCalculator do
  describe '.calculate_positions' do
    subject(:positions) do
      TypeBalancer::Distributor.calculate_target_positions(
        total_count: total_count,
        ratio: ratio,
        available_positions: available_items
      )
    end

    let(:available_items) { nil }
    let(:total_count) { 10 }
    let(:ratio) { 0.3 }

    context 'with invalid inputs' do
      it 'returns empty array for zero total count' do
        expect(TypeBalancer::Distributor.calculate_target_positions(total_count: 0, ratio: 0.5)).to eq([])
      end

      it 'returns empty array for zero ratio' do
        expect(TypeBalancer::Distributor.calculate_target_positions(total_count: 10, ratio: 0)).to eq([])
      end

      it 'returns empty array for negative total count' do
        expect(TypeBalancer::Distributor.calculate_target_positions(total_count: -1, ratio: 0.5)).to eq([])
      end

      it 'returns empty array for negative ratio' do
        expect(TypeBalancer::Distributor.calculate_target_positions(total_count: 10, ratio: -0.1)).to eq([])
      end

      it 'returns empty array for ratio greater than 1' do
        expect(TypeBalancer::Distributor.calculate_target_positions(total_count: 10, ratio: 1.1)).to eq([])
      end
    end

    context 'with available items' do
      context 'with invalid available items' do
        it 'uses available positions as provided' do
          expect(TypeBalancer::Distributor.calculate_target_positions(
                   total_count: 5,
                   ratio: 0.4,
                   available_positions: [0, 5, 6]
                 )).to eq([0, 6])
        end
      end

      context 'with single target position' do
        let(:total_count) { 5 }
        let(:ratio) { 0.2 }
        let(:available_items) { [1, 2, 3] }

        it 'uses first available position' do
          expect(positions).to eq([1])
        end
      end

      context 'with multiple target positions' do
        let(:total_count) { 10 }
        let(:ratio) { 0.2 }
        let(:available_items) { [1, 3, 5] }

        it 'uses first and last available positions' do
          expect(positions).to eq([1, 5])
        end
      end

      context 'with exact match of available positions' do
        let(:total_count) { 10 }
        let(:ratio) { 0.3 }
        let(:available_items) { [2, 4, 6] }

        it 'uses all available positions' do
          expect(positions).to eq([2, 4, 6])
        end
      end
    end

    context 'with special ratios' do
      context 'with two-thirds ratio in three slots' do
        let(:total_count) { 3 }
        let(:ratio) { 0.67 }

        it 'returns [0, 1]' do
          expect(positions).to eq([0, 1])
        end
      end

      context 'with one-third ratio in three slots' do
        let(:total_count) { 3 }
        let(:ratio) { 0.34 }

        it 'returns [0]' do
          expect(positions).to eq([0])
        end
      end
    end
  end
end

RSpec.describe TypeBalancer::PositionCalculator::PositionBatch do
  describe '#initialize' do
    it 'initializes with required parameters' do
      batch = described_class.new(total_count: 10, ratio: 0.5)
      expect(batch.total_count).to eq(10)
      expect(batch.ratio).to eq(0.5)
      expect(batch.available_items).to be_nil
    end

    it 'initializes with optional available_items' do
      batch = described_class.new(total_count: 10, ratio: 0.5, available_items: [1, 2, 3])
      expect(batch.available_items).to eq([1, 2, 3])
    end
  end

  describe '#valid?' do
    it 'returns true for valid basic inputs' do
      batch = described_class.new(total_count: 10, ratio: 0.5)
      expect(batch).to be_valid
    end

    it 'returns false for negative total_count' do
      batch = described_class.new(total_count: -1, ratio: 0.5)
      expect(batch).not_to be_valid
    end

    it 'returns false for negative ratio' do
      batch = described_class.new(total_count: 10, ratio: -0.1)
      expect(batch).not_to be_valid
    end

    it 'returns false for ratio greater than 1' do
      batch = described_class.new(total_count: 10, ratio: 1.1)
      expect(batch).not_to be_valid
    end

    context 'with available_items' do
      it 'returns true for valid available items' do
        batch = described_class.new(total_count: 10, ratio: 0.5, available_items: [1, 2, 3])
        expect(batch).to be_valid
      end

      it 'returns false for non-array available items' do
        batch = described_class.new(total_count: 10, ratio: 0.5, available_items: 'not an array')
        expect(batch).not_to be_valid
      end

      it 'returns false for array with non-integer items' do
        batch = described_class.new(total_count: 10, ratio: 0.5, available_items: [1, 'two', 3])
        expect(batch).not_to be_valid
      end

      it 'returns false for items outside valid range' do
        batch = described_class.new(total_count: 10, ratio: 0.5, available_items: [0, 10, 20])
        expect(batch).not_to be_valid
      end

      it 'returns false for negative indices' do
        batch = described_class.new(total_count: 10, ratio: 0.5, available_items: [-1, 0, 1])
        expect(batch).not_to be_valid
      end
    end
  end

  describe '#target_count' do
    it 'calculates target count correctly' do
      batch = described_class.new(total_count: 10, ratio: 0.3)
      expect(batch.target_count).to eq(3)
    end

    it 'rounds target count to nearest integer' do
      batch = described_class.new(total_count: 10, ratio: 0.35)
      expect(batch.target_count).to eq(4)
    end
  end
end
