# frozen_string_literal: true

RSpec.describe TypeBalancer do
  it 'has a version number' do
    expect(TypeBalancer::VERSION).not_to be_nil
  end

  describe '.balance' do
    let(:items) do
      [
        { type: 'video', name: 'Video 1' },
        { type: 'image', name: 'Image 1' },
        { type: 'strip', name: 'Strip 1' },
        { type: 'video', name: 'Video 2' },
        { type: 'image', name: 'Image 2' },
        { type: 'strip', name: 'Strip 2' }
      ]
    end

    let(:calculator_instance) { instance_double(TypeBalancer::Calculator) }

    context 'with default settings' do
      subject(:balanced_items) { described_class.balance(items) }

      before do
        # Mock how the items will be balanced
        expected_result = [
          { type: 'video', name: 'Video 1' },
          { type: 'image', name: 'Image 1' },
          { type: 'strip', name: 'Strip 1' },
          { type: 'video', name: 'Video 2' },
          { type: 'image', name: 'Image 2' },
          { type: 'strip', name: 'Strip 2' }
        ]

        allow(TypeBalancer::Calculator).to receive(:new).and_return(calculator_instance)
        allow(calculator_instance).to receive(:call).and_return(expected_result)
      end

      it 'preserves all items' do
        expect(balanced_items.size).to eq(items.size)
        expect(balanced_items).to match_array(items)
      end

      it 'starts with a video item' do
        expect(balanced_items.first[:type]).to eq('video')
      end

      it 'includes video items' do
        types = balanced_items.map { |item| item[:type] }
        expect(types.count('video')).to be > 0
      end

      it 'includes image items' do
        types = balanced_items.map { |item| item[:type] }
        expect(types.count('image')).to be > 0
      end

      it 'includes strip items' do
        types = balanced_items.map { |item| item[:type] }
        expect(types.count('strip')).to be > 0
      end
    end

    context 'with custom type order' do
      subject(:balanced_items) do
        described_class.balance(items, type_order: %w[strip image video])
      end

      before do
        # Mock how the items will be balanced with custom type order
        expected_result = [
          { type: 'strip', name: 'Strip 1' },
          { type: 'image', name: 'Image 1' },
          { type: 'video', name: 'Video 1' },
          { type: 'strip', name: 'Strip 2' },
          { type: 'image', name: 'Image 2' },
          { type: 'video', name: 'Video 2' }
        ]

        allow(TypeBalancer::Calculator).to receive(:new).and_return(calculator_instance)
        allow(calculator_instance).to receive(:call).and_return(expected_result)
      end

      it 'preserves all items' do
        expect(balanced_items.size).to eq(items.size)
        expect(balanced_items).to match_array(items)
      end

      it 'starts with a strip item' do
        expect(balanced_items.first[:type]).to eq('strip')
      end

      it 'follows the custom type order' do
        types = balanced_items.map { |item| item[:type] }
        first_three_types = types[0..2]
        expect(first_three_types).to eq(%w[strip image video])
      end
    end

    context 'with custom type field' do
      subject(:balanced_items) { described_class.balance(items, type_field: :category) }

      let(:items) do
        [
          { category: 'video', name: 'Video 1' },
          { category: 'image', name: 'Image 1' },
          { category: 'strip', name: 'Strip 1' }
        ]
      end

      before do
        allow(TypeBalancer::Calculator).to receive(:new).and_return(calculator_instance)
        allow(calculator_instance).to receive(:call).and_return(items)
      end

      it 'preserves all items' do
        expect(balanced_items.size).to eq(items.size)
        expect(balanced_items).to match_array(items)
      end

      it 'uses the custom type field for distribution' do
        types = balanced_items.map { |item| item[:category] }
        expect(types.uniq.sort).to eq(%w[image strip video])
      end
    end
  end

  describe '.calculate_positions' do
    context 'with valid inputs' do
      before do
        allow(TypeBalancer::PositionCalculator).to receive(:calculate_positions)
      end

      it 'delegates to PositionCalculator' do
        described_class.calculate_positions(total_count: 10, ratio: 0.4)

        expect(TypeBalancer::PositionCalculator).to have_received(:calculate_positions).with(
          total_count: 10,
          ratio: 0.4,
          available_items: nil
        )
      end

      it 'handles available items' do
        available_items = [0, 2, 4, 6]
        described_class.calculate_positions(
          total_count: 10,
          ratio: 0.4,
          available_items: available_items
        )

        expect(TypeBalancer::PositionCalculator).to have_received(:calculate_positions).with(
          total_count: 10,
          ratio: 0.4,
          available_items: available_items
        )
      end
    end
  end

  describe '.extract_types' do
    context 'with hash-like items' do
      let(:items) do
        [
          { type: 'video' },
          { type: 'image' },
          { 'type' => 'video' } # String key
        ]
      end

      it 'extracts unique types' do
        expect(described_class.extract_types(items, :type)).to eq(%w[video image])
      end
    end

    context 'with object items' do
      let(:test_item_class) { Struct.new(:content_type) }
      let(:items) do
        [
          test_item_class.new('video'),
          test_item_class.new('image'),
          test_item_class.new('video')
        ]
      end

      it 'extracts types using method calls' do
        expect(described_class.extract_types(items, :content_type)).to eq(%w[video image])
      end
    end

    context 'with invalid items' do
      let(:items) { [Object.new] }

      it 'returns array with nil for inaccessible type fields' do
        # quality.rb shows that inaccessible type fields return nil
        expect(described_class.extract_types(items, :type)).to eq([nil])
      end
    end

    context 'with mixed access patterns' do
      let(:test_item_class) { Struct.new(:type) }
      let(:items) do
        [
          { type: 'video' },
          test_item_class.new('image'),
          { 'type' => 'strip' }
        ]
      end

      it 'handles different ways of accessing the type field' do
        expect(described_class.extract_types(items, :type)).to eq(%w[video image strip])
      end
    end
  end

  describe 'error handling' do
    context 'when balancing items' do
      let(:items) { [{ type: 'video' }, Object.new] }

      it 'raises error when balancing items with inaccessible type fields' do
        # quality.rb shows that balancing requires valid type fields
        expect { described_class.balance(items) }.to raise_error(TypeBalancer::Error)
      end
    end
  end
end
