# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Balancer do
  let(:balancer) { described_class.new(items, type_field: :type) }

  describe '#call' do
    subject(:result) { balancer.call }

    context 'with objects responding to type_field' do
      let(:video_first) { double('Item', type: 'video', name: 'Video First') }
      let(:video_second) { double('Item', type: 'video', name: 'Video Second') }
      let(:image_first) { double('Item', type: 'image', name: 'Image First') }
      let(:image_second) { double('Item', type: 'image', name: 'Image Second') }
      let(:image_third) { double('Item', type: 'image', name: 'Image Third') }
      let(:strip_first) { double('Item', type: 'strip', name: 'Strip First') }

      let(:items) { [video_first, image_first, strip_first, video_second, image_second, image_third] }

      it 'distributes items evenly by type' do
        expect(result).to eq([video_first, image_first, strip_first, video_second, image_second, image_third])
      end
    end

    context 'with empty collection' do
      let(:items) { [] }

      it 'returns an empty array' do
        expect(result).to be_empty
      end
    end

    context 'with single type' do
      let(:items) { [double('Item', type: 'video', name: 'Video')] }

      it 'returns the original array' do
        expect(result).to eq(items)
      end
    end

    context 'with hash objects' do
      let(:items) do
        [
          { type: 'video', name: 'Video 1' },
          { type: 'image', name: 'Image 1' },
          { type: 'strip', name: 'Strip 1' }
        ]
      end

      it 'processes hash objects correctly' do
        expect(result.first[:type]).to eq('video')
      end

      it 'includes all items in the result' do
        expect(result).to match_array(items)
      end
    end

    context 'with string keys' do
      let(:balancer) { described_class.new(items, type_field: 'type') }
      let(:items) do
        [
          { 'type' => 'video', 'name' => 'Video 1' },
          { 'type' => 'image', 'name' => 'Image 1' },
          { 'type' => 'strip', 'name' => 'Strip 1' }
        ]
      end

      it 'processes string keys correctly' do
        expect(result.first['type']).to eq('video')
      end

      it 'includes all items in the result' do
        expect(result).to match_array(items)
      end
    end

    context 'with custom type order' do
      let(:distribution_calculator) { instance_double(TypeBalancer::DistributionCalculator) }
      let(:balancer) do
        described_class.new(
          items,
          type_field: :type,
          types: %w[image video strip],
          distribution_calculator: distribution_calculator
        )
      end

      let(:items) do
        [
          { type: 'video', name: 'Video 1' },
          { type: 'strip', name: 'Strip 1' },
          { type: 'image', name: 'Image 1' }
        ]
      end

      before do
        allow(distribution_calculator).to receive(:calculate_target_positions)
          .with(3, 1)
          .and_return([0])
      end

      it 'respects the custom type order' do
        expect(result[0][:type]).to eq('image')
      end
    end

    context 'with invalid items' do
      let(:invalid_item) { Object.new } # Object with no type field
      let(:items) { [invalid_item] }

      it 'raises an error' do
        expect { result }.to raise_error(TypeBalancer::Error)
      end
    end

    context 'with single type and unused primary items' do
      let(:items) do
        [
          { type: 'video', name: 'Video 1' },
          { type: 'video', name: 'Video 2' },
          { type: 'video', name: 'Video 3' }
        ]
      end

      let(:distribution_calculator) { instance_double(TypeBalancer::DistributionCalculator) }
      let(:balancer) do
        described_class.new(
          items,
          type_field: :type,
          distribution_calculator: distribution_calculator
        )
      end

      before do
        allow(distribution_calculator).to receive(:calculate_target_positions)
          .with(3, 3)
          .and_return([0, 1])
      end

      it 'handles unused primary items correctly' do
        expect(result[1][:name]).to eq('Video 2')
      end
    end

    context 'with no remaining types' do
      let(:items) do
        [
          { type: 'video', name: 'Video 1' },
          { type: 'video', name: 'Video 2' }
        ]
      end

      let(:distribution_calculator) { instance_double(TypeBalancer::DistributionCalculator) }
      let(:balancer) do
        described_class.new(
          items,
          type_field: :type,
          distribution_calculator: distribution_calculator
        )
      end

      before do
        allow(distribution_calculator).to receive(:calculate_target_positions)
          .with(2, 2)
          .and_return([0, 1])
      end

      it 'places all items in calculated positions' do
        expect(result).to eq(items)
      end
    end
  end
end
