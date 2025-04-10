# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Balancer do
  let(:types) { %w[video image strip] }
  let(:balancer) { described_class.new(types) }

  describe '#initialize' do
    it 'accepts an array of types' do
      expect { described_class.new(%w[video image]) }.not_to raise_error
    end

    it 'accepts a single type' do
      expect { described_class.new('video') }.not_to raise_error
    end

    it 'raises error for empty types' do
      expect { described_class.new([]) }.to raise_error(ArgumentError, 'Types cannot be empty')
    end
  end

  describe '#call' do
    subject(:result) { balancer.call(collection) }

    context 'with valid input' do
      let(:collection) do
        [
          { type: 'video', id: 1 },
          { type: 'image', id: 2 },
          { type: 'strip', id: 3 }
        ]
      end

      it 'returns all input items' do
        expect(result).to match_array(collection)
      end

      it 'maintains data integrity' do
        expect(result.map { |item| item[:id] }).to contain_exactly(1, 2, 3)
      end
    end

    context 'with empty collection' do
      let(:collection) { [] }

      it 'raises ArgumentError' do
        expect { result }.to raise_error(ArgumentError, 'Collection cannot be empty')
      end
    end

    context 'with invalid type' do
      let(:collection) do
        [
          { type: 'video', id: 1 },
          { type: 'invalid', id: 2 }
        ]
      end

      it 'raises TypeBalancer::Error' do
        expect { result }.to raise_error(TypeBalancer::Error, /Invalid type/)
      end
    end

    context 'with missing type field' do
      let(:collection) do
        [
          { type: 'video', id: 1 },
          { id: 2 }
        ]
      end

      it 'raises TypeBalancer::Error' do
        expect { result }.to raise_error(TypeBalancer::Error, /Cannot access type field/)
      end
    end

    context 'with mixed item types' do
      let(:video) { double('Item', type: 'video', id: 1) }
      let(:collection) do
        [
          video,
          { type: 'image', id: 2 },
          { 'type' => 'strip', id: 3 }
        ]
      end

      it 'handles different item types correctly' do
        expect(result).to match_array(collection)
      end
    end
  end
end
