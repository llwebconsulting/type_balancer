# frozen_string_literal: true

RSpec.describe TypeBalancer::TypeExtractor do
  let(:type_field) { :category }
  let(:extractor) { described_class.new(type_field) }

  describe '#extract_types' do
    context 'with hash items' do
      let(:collection) do
        [
          { category: 'A', value: 1 },
          { category: 'B', value: 2 },
          { category: 'A', value: 3 }
        ]
      end

      it 'extracts unique types using the specified field' do
        expect(extractor.extract_types(collection)).to eq(%w[A B])
      end
    end

    context 'with object items' do
      let(:item_class) do
        Struct.new(:category, :value)
      end

      let(:collection) do
        [
          item_class.new('A', 1),
          item_class.new('B', 2),
          item_class.new('A', 3)
        ]
      end

      it 'extracts unique types using the specified method' do
        expect(extractor.extract_types(collection)).to eq(%w[A B])
      end
    end

    context 'with invalid items' do
      let(:collection) { [1, 2, 3] }

      it 'raises an error' do
        expect { extractor.extract_types(collection) }.to raise_error(TypeBalancer::Error)
      end
    end
  end

  describe '#group_by_type' do
    context 'with hash items' do
      let(:collection) do
        [
          { category: 'A', value: 1 },
          { category: 'B', value: 2 },
          { category: 'A', value: 3 }
        ]
      end

      it 'groups items by the specified field' do
        result = extractor.group_by_type(collection)
        expect(result).to eq({
                               'A' => [
                                 { category: 'A', value: 1 },
                                 { category: 'A', value: 3 }
                               ],
                               'B' => [
                                 { category: 'B', value: 2 }
                               ]
                             })
      end
    end

    context 'with object items' do
      let(:item_class) do
        Struct.new(:category, :value)
      end

      let(:collection) do
        [
          item_class.new('A', 1),
          item_class.new('B', 2),
          item_class.new('A', 3)
        ]
      end

      it 'groups items by the specified method' do
        result = extractor.group_by_type(collection)
        expect(result['A'].map(&:value)).to eq([1, 3])
        expect(result['B'].map(&:value)).to eq([2])
      end
    end

    context 'with string keys' do
      let(:collection) do
        [
          { 'category' => 'A', 'value' => 1 },
          { 'category' => 'B', 'value' => 2 },
          { 'category' => 'A', 'value' => 3 }
        ]
      end

      it 'groups items by the string key' do
        result = extractor.group_by_type(collection)
        expect(result).to eq({
                               'A' => [
                                 { 'category' => 'A', 'value' => 1 },
                                 { 'category' => 'A', 'value' => 3 }
                               ],
                               'B' => [
                                 { 'category' => 'B', 'value' => 2 }
                               ]
                             })
      end
    end

    context 'with invalid items' do
      let(:collection) { [1, 2, 3] }

      it 'raises an error' do
        expect { extractor.group_by_type(collection) }.to raise_error(TypeBalancer::Error)
      end
    end
  end
end
