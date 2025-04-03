# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Balancer do
  let(:distribution_calculator) { instance_double(TypeBalancer::DistributionCalculator) }
  let(:balancer) { described_class.new(items, type_field: :type, distribution_calculator: distribution_calculator) }

  describe '#call' do
    subject(:result) { balancer.call }

    context 'with objects responding to type_field' do
      let(:video_first) { double('Item', type: 'video', name: 'Video First') }
      let(:video_second) { double('Item', type: 'video', name: 'Video Second') }
      let(:image_first) { double('Item', type: 'image', name: 'Image First') }
      let(:image_second) { double('Item', type: 'image', name: 'Image Second') }
      let(:strip_first) { double('Item', type: 'strip', name: 'Strip First') }

      let(:items) { [video_first, image_first, strip_first, video_second, image_second] }

      before do
        # Mock distribution calculator for each type
        allow(distribution_calculator).to receive(:calculate_target_positions)
          .with(5, 2, 0.4)  # video type (primary)
          .and_return([0, 3])
        allow(distribution_calculator).to receive(:calculate_target_positions)
          .with(5, 2, 0.3)  # image type
          .and_return([1, 4])
        allow(distribution_calculator).to receive(:calculate_target_positions)
          .with(5, 1, 0.3)  # strip type
          .and_return([2])
      end

      it 'includes all items in the result' do
        # Verify that all the original items are present
        expect(result).to match_array(items)
      end

      it 'places items of each type at appropriate positions' do
        # Expect right number of each type
        video_items = result.select { |item| item.type == 'video' }
        image_items = result.select { |item| item.type == 'image' }
        strip_items = result.select { |item| item.type == 'strip' }

        expect(video_items.size).to eq(2)
        expect(image_items.size).to eq(2)
        expect(strip_items.size).to eq(1)
      end
    end

    context 'with empty collection' do
      let(:items) { [] }

      it 'returns an empty array' do
        expect(result).to be_empty
      end
    end

    context 'with single type' do
      let(:video) { double('Item', type: 'video', name: 'Video') }
      let(:items) { [video] }

      before do
        allow(distribution_calculator).to receive(:calculate_target_positions)
          .with(1, 1, 1.0)
          .and_return([0])
      end

      it 'uses full ratio for single type' do
        expect(result).to eq([video])
      end
    end

    context 'with hash objects' do
      let(:items) do
        [
          { type: 'video', name: 'Video 1' },
          { type: 'image', name: 'Image 1' }
        ]
      end

      before do
        allow(distribution_calculator).to receive(:calculate_target_positions)
          .with(2, 1, 0.4)
          .and_return([0])
        allow(distribution_calculator).to receive(:calculate_target_positions)
          .with(2, 1, 0.3)
          .and_return([1])
      end

      it 'handles hash type access correctly' do
        expect(result.map { |item| item[:type] }).to eq(%w[video image])
      end
    end

    context 'with string keys' do
      let(:balancer) do
        described_class.new(items, type_field: 'type', distribution_calculator: distribution_calculator)
      end
      let(:items) do
        [
          { 'type' => 'video', 'name' => 'Video 1' },
          { 'type' => 'image', 'name' => 'Image 1' }
        ]
      end

      before do
        allow(distribution_calculator).to receive(:calculate_target_positions)
          .with(2, 1, 0.4)
          .and_return([0])
        allow(distribution_calculator).to receive(:calculate_target_positions)
          .with(2, 1, 0.3)
          .and_return([1])
      end

      it 'handles string key access correctly' do
        expect(result.map { |item| item['type'] }).to eq(%w[video image])
      end
    end

    context 'with invalid items' do
      let(:invalid_item) { Object.new } # Object with no type field
      let(:items) { [invalid_item] }

      it 'raises an error' do
        expect { result }.to raise_error(TypeBalancer::Error, /Cannot access type field/)
      end
    end
  end
end
