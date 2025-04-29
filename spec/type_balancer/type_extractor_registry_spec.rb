# frozen_string_literal: true

RSpec.describe TypeBalancer::TypeExtractorRegistry do
  let(:type_field) { :category }

  describe '.get' do
    it 'returns a TypeExtractor instance' do
      extractor = described_class.get(type_field)
      expect(extractor).to be_a(TypeBalancer::TypeExtractor)
    end

    it 'memoizes extractors per type_field' do
      first_call = described_class.get(type_field)
      second_call = described_class.get(type_field)
      expect(first_call).to be(second_call)
    end

    it 'creates different extractors for different type_fields' do
      category_extractor = described_class.get(:category)
      type_extractor = described_class.get(:type)
      expect(category_extractor).not_to be(type_extractor)
    end
  end

  describe '.clear!' do
    it 'clears the registry cache' do
      first_extractor = described_class.get(type_field)
      described_class.clear!
      second_extractor = described_class.get(type_field)
      expect(first_extractor).not_to be(second_extractor)
    end
  end

  describe '.cache' do
    it 'returns a hash' do
      expect(described_class.cache).to be_a(Hash)
    end

    it 'is thread-local' do
      thread_cache = nil
      main_cache = described_class.cache

      Thread.new do
        thread_cache = described_class.cache
      end.join

      expect(thread_cache).not_to be(main_cache)
    end
  end
end
