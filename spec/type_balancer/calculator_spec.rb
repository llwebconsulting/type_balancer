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

    context 'with invalid inputs' do
      it 'raises error for nil items' do
        expect { described_class.new(nil) }.to raise_error(ArgumentError, 'Items cannot be nil')
      end

      it 'raises error for invalid type field' do
        items = [{ id: 1 }]
        expect { described_class.new(items, type_field: nil) }.to raise_error(ArgumentError, 'Type field cannot be nil')
      end

      it 'raises error for items with missing type field' do
        items = [{ other_field: 'value' }]
        expect { described_class.new(items).call }.to raise_error(ArgumentError, 'All items must have a type field')
      end

      it 'raises error for items with empty type value' do
        items = [{ type: '' }]
        expect { described_class.new(items).call }.to raise_error(ArgumentError, 'Type values cannot be empty')
      end
    end
  end

  describe '#call' do
    context 'with empty items' do
      it 'returns an empty array' do
        expect(calculator.call).to eq([])
      end
    end

    context 'with single type' do
      let(:items) { [{ type: 'video', id: 1 }, { type: 'video', id: 2 }] }

      it 'maintains original order for single type' do
        expect(calculator.call).to eq(items)
      end
    end

    context 'with multiple types' do
      let(:items) do
        [
          { type: 'video', id: 1 },
          { type: 'image', id: 2 },
          { type: 'video', id: 3 },
          { type: 'image', id: 4 }
        ]
      end

      it 'distributes items according to type ratios' do
        result = calculator.call
        expect(result.map { |i| i[:type] }).to eq(%w[video image video image])
        expect(result.map { |i| i[:id] }).to eq([1, 2, 3, 4])
      end

      it 'maintains relative order within each type' do
        result = calculator.call
        video_items = result.select { |i| i[:type] == 'video' }
        image_items = result.select { |i| i[:type] == 'image' }

        expect(video_items.map { |i| i[:id] }).to eq([1, 3])
        expect(image_items.map { |i| i[:id] }).to eq([2, 4])
      end
    end

    context 'with uneven type distribution' do
      let(:items) do
        [
          { type: 'video', id: 1 },
          { type: 'image', id: 2 },
          { type: 'video', id: 3 },
          { type: 'video', id: 4 },
          { type: 'image', id: 5 }
        ]
      end

      it 'handles uneven distribution while maintaining type order' do
        result = calculator.call
        expect(result.map { |i| i[:type] }).to eq(%w[video image video video image])
        expect(result.map { |i| i[:id] }).to eq([1, 2, 3, 4, 5])
      end
    end
  end

  describe '#calculate_ratio' do
    it 'returns 1.0 for single type' do
      expect(calculator.send(:calculate_ratio, 1, 0)).to eq(1.0)
    end

    it 'returns correct ratios for two types' do
      expect(calculator.send(:calculate_ratio, 2, 0)).to eq(0.6)
      expect(calculator.send(:calculate_ratio, 2, 1)).to eq(0.4)
    end

    it 'returns correct ratios for three or more types' do
      expect(calculator.send(:calculate_ratio, 3, 0)).to eq(0.4)
      expect(calculator.send(:calculate_ratio, 3, 1)).to eq(0.3)
      expect(calculator.send(:calculate_ratio, 3, 2)).to eq(0.3)
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

  describe '#place_items_at_positions' do
    let(:items) do
      [
        { type: 'video', id: 1 },
        { type: 'video', id: 2 },
        { type: 'image', id: 3 },
        { type: 'image', id: 4 },
        { type: 'video', id: 5 }
      ]
    end

    it 'handles remaining items correctly' do
      items_by_type = [
        items.select { |i| i[:type] == 'video' },
        items.select { |i| i[:type] == 'image' }
      ]
      target_positions = [[0, 2], [1]]

      result = calculator.send(:place_items_at_positions, items_by_type, target_positions)
      expect(result.map { |i| i[:id] }).to eq([1, 3, 2, 4, 5])
    end
  end

  describe '#calculate_target_positions' do
    it 'handles single item type with single position' do
      calculator = described_class.new([{ type: 'video' }])
      items_by_type = [['video']]
      positions = calculator.send(:calculate_target_positions, items_by_type)
      expect(positions).to eq([[0]])
    end

    it 'handles multiple types with single positions' do
      calculator = described_class.new([
                                         { type: 'video' },
                                         { type: 'image' }
                                       ])
      items_by_type = [['video'], ['image']]
      positions = calculator.send(:calculate_target_positions, items_by_type)
      expect(positions).to eq([[0], [1]])
    end
  end

  describe '#place_items_at_positions' do
    it 'handles nil positions for a type' do
      calculator = described_class.new([
                                         { type: 'video', id: 1 },
                                         { type: 'image', id: 2 }
                                       ])
      items_by_type = [[{ type: 'video', id: 1 }], [{ type: 'image', id: 2 }]]
      target_positions = [[0], nil]
      result = calculator.send(:place_items_at_positions, items_by_type, target_positions)
      expect(result.map { |i| i[:id] }).to eq([1, 2])
    end
  end
end

RSpec.describe TypeBalancer::PositionCalculator do
  describe '.calculate_positions' do
    it 'returns nil for invalid inputs' do
      expect(described_class.calculate_positions(total_count: -1, ratio: 0.5)).to be_nil
      expect(described_class.calculate_positions(total_count: 10, ratio: -0.1)).to be_nil
      expect(described_class.calculate_positions(total_count: 10, ratio: 1.5)).to be_nil
    end

    it 'returns empty array for zero total count' do
      expect(described_class.calculate_positions(total_count: 0, ratio: 0.5)).to eq([])
    end

    it 'returns [0] for target count of 1' do
      expect(described_class.calculate_positions(total_count: 10, ratio: 0.1)).to eq([0])
    end

    context 'with available items' do
      it 'returns subset when available items are fewer than target' do
        result = described_class.calculate_positions(
          total_count: 10,
          ratio: 0.5,
          available_items: [1, 3, 5]
        )
        expect(result).to eq([1, 3, 5])
      end

      it 'distributes items evenly when more available than target' do
        result = described_class.calculate_positions(
          total_count: 10,
          ratio: 0.3,
          available_items: [0, 2, 4, 6, 8]
        )
        expect(result).to eq([0, 4, 8])
      end

      it 'validates available items are within bounds' do
        result = described_class.calculate_positions(
          total_count: 5,
          ratio: 0.5,
          available_items: [0, 2, 10]
        )
        expect(result).to be_nil
      end

      it 'handles positions exceeding total count' do
        result = described_class.calculate_positions(
          total_count: 5,
          ratio: 0.4,
          available_items: [6, 7, 8] # Invalid positions
        )
        expect(result).to be_nil
      end

      it 'handles single target count with multiple available items' do
        result = described_class.calculate_positions(
          total_count: 5,
          ratio: 0.2, # Will result in target_count of 1
          available_items: [1, 2, 3]
        )
        expect(result).to eq([1])
      end
    end

    context 'with boundary conditions' do
      it 'handles ratio of 0.0' do
        expect(described_class.calculate_positions(total_count: 10, ratio: 0.0)).to eq([])
      end

      it 'handles ratio of 1.0' do
        expect(described_class.calculate_positions(total_count: 5, ratio: 1.0)).to eq([0, 1, 2, 3, 4])
      end

      it 'handles floating point precision edge cases' do
        expect(described_class.calculate_positions(total_count: 3, ratio: 0.333333)).to eq([0])
        expect(described_class.calculate_positions(total_count: 3, ratio: 0.666667)).to eq([0, 1])
      end

      it 'validates total_count is positive' do
        expect(described_class.calculate_positions(total_count: 0, ratio: 0.5)).to eq([])
        expect(described_class.calculate_positions(total_count: -1, ratio: 0.5)).to be_nil
      end

      it 'validates ratio is between 0 and 1' do
        expect(described_class.calculate_positions(total_count: 10, ratio: -0.1)).to be_nil
        expect(described_class.calculate_positions(total_count: 10, ratio: 1.1)).to be_nil
      end
    end

    context 'with edge cases' do
      it 'handles target count of 1 with available items' do
        result = described_class.calculate_positions(
          total_count: 5,
          ratio: 0.2,
          available_items: [1, 2, 3, 4]
        )
        expect(result).to eq([1])
      end

      it 'handles target count of 1 without available items' do
        result = described_class.calculate_positions(
          total_count: 5,
          ratio: 0.2
        )
        expect(result).to eq([0])
      end

      it 'handles ratio close to 2/3 with total count of 3' do
        result = described_class.calculate_positions(
          total_count: 3,
          ratio: 0.666667
        )
        expect(result).to eq([0, 1])
      end

      it 'handles available items with target count of 1' do
        result = described_class.calculate_positions(
          total_count: 5,
          ratio: 0.2,
          available_items: [2]
        )
        expect(result).to eq([2])
      end

      it 'handles available items exactly matching target count' do
        result = described_class.calculate_positions(
          total_count: 10,
          ratio: 0.3,
          available_items: [1, 2, 3]
        )
        expect(result).to eq([1, 2, 3])
      end

      it 'handles zero ratio' do
        result = described_class.calculate_positions(
          total_count: 10,
          ratio: 0.0
        )
        expect(result).to eq([])
      end

      it 'handles ratio of 1.0' do
        result = described_class.calculate_positions(
          total_count: 3,
          ratio: 1.0
        )
        expect(result).to eq([0, 1, 2])
      end
    end

    context 'with complex edge cases' do
      it 'handles available items with single target position' do
        result = described_class.calculate_positions(
          total_count: 5,
          ratio: 0.2,
          available_items: [0, 2, 4]
        )
        expect(result).to eq([0])
      end

      it 'handles available items with even distribution' do
        result = described_class.calculate_positions(
          total_count: 10,
          ratio: 0.5,
          available_items: [0, 2, 4, 6, 8]
        )
        expect(result).to eq([0, 2, 4, 6, 8])
      end

      it 'handles target count equal to available items size' do
        result = described_class.calculate_positions(
          total_count: 6,
          ratio: 0.5,
          available_items: [1, 3, 5]
        )
        expect(result).to eq([1, 3, 5])
      end

      it 'handles floating point precision edge case with ratio 0.333333' do
        result = described_class.calculate_positions(
          total_count: 3,
          ratio: 0.333333
        )
        expect(result).to eq([0])
      end

      it 'handles floating point precision edge case with ratio 0.666667' do
        result = described_class.calculate_positions(
          total_count: 3,
          ratio: 0.666667
        )
        expect(result).to eq([0, 1])
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
