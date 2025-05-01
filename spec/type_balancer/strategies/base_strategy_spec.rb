# frozen_string_literal: true

RSpec.describe TypeBalancer::Strategies::BaseStrategy do
  let(:items) do
    [
      { type: 'video', id: 1 },
      { type: 'image', id: 2 },
      { type: 'article', id: 3 }
    ]
  end

  let(:strategy) { described_class.new(items: items, type_field: :type) }

  describe '#initialize' do
    it 'sets instance variables' do
      expect(strategy.instance_variable_get(:@items)).to eq(items)
      expect(strategy.instance_variable_get(:@type_field)).to eq(:type)
    end

    it 'accepts custom types' do
      custom_types = %w[video image]
      strategy = described_class.new(items: items, type_field: :type, types: custom_types)
      expect(strategy.instance_variable_get(:@types)).to eq(custom_types)
    end
  end

  describe '#balance' do
    it 'raises NotImplementedError' do
      expect { strategy.balance }.to raise_error(NotImplementedError)
    end
  end

  describe '#validate_items!' do
    context 'with valid items' do
      it 'does not raise error' do
        expect { strategy.send(:validate_items!) }.not_to raise_error
      end
    end

    context 'with invalid items' do
      it 'raises error when type field is missing' do
        invalid_items = [{ id: 1 }]
        strategy = described_class.new(items: invalid_items, type_field: :type)
        expect { strategy.send(:validate_items!) }.to raise_error(ArgumentError)
      end

      it 'raises error when type value is empty' do
        invalid_items = [{ type: '', id: 1 }]
        strategy = described_class.new(items: invalid_items, type_field: :type)
        expect { strategy.send(:validate_items!) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#extract_types' do
    it 'extracts unique types in correct order' do
      items = [
        { type: 'video', id: 1 },
        { type: 'custom', id: 2 },
        { type: 'image', id: 3 },
        { type: 'video', id: 4 }
      ]
      strategy = described_class.new(items: items, type_field: :type)
      types = strategy.send(:extract_types)

      # Should maintain DEFAULT_TYPE_ORDER for known types
      expect(types.first(2)).to eq(%w[video image])
      # Should append unknown types at the end
      expect(types.last).to eq('custom')
    end
  end

  describe '#group_items_by_type' do
    it 'groups items by their type' do
      items = [
        { type: 'video', id: 1 },
        { type: 'image', id: 2 },
        { type: 'video', id: 3 }
      ]
      strategy = described_class.new(items: items, type_field: :type)
      strategy.instance_variable_set(:@types, %w[video image])

      grouped = strategy.send(:group_items_by_type)
      expect(grouped['video'].size).to eq(2)
      expect(grouped['image'].size).to eq(1)
      expect(grouped['video'].map { |i| i[:id] }).to contain_exactly(1, 3)
    end
  end
end
