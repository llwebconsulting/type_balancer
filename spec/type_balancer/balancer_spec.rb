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
          .with(5, 2, 0.4) # video type (primary)
          .and_return([0, 3])
        allow(distribution_calculator).to receive(:calculate_target_positions)
          .with(5, 2, 0.3)  # image type (remaining ratio = 0.6 / 2 = 0.3)
          .and_return([1, 4])
        allow(distribution_calculator).to receive(:calculate_target_positions)
          .with(5, 1, 0.3)  # strip type (remaining ratio = 0.6 / 2 = 0.3)
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
          .with(2, 1, 0.6)  # For two types, first type gets 0.6
          .and_return([0])
        allow(distribution_calculator).to receive(:calculate_target_positions)
          .with(2, 1, 0.4)  # For two types, second type gets 0.4
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
          .with(2, 1, 0.6)  # For two types, first type gets 0.6
          .and_return([0])
        allow(distribution_calculator).to receive(:calculate_target_positions)
          .with(2, 1, 0.4)  # For two types, second type gets 0.4
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

    context 'with large collections' do
      let(:batch_size) { TypeBalancer::Balancer::BATCH_SIZE }
      let(:large_collection_size) { (batch_size * 2) + 100 } # More than 2 batches

      let(:items) do
        large_collection_size.times.map do |i|
          type = case i % 3
                 when 0 then 'video'
                 when 1 then 'image'
                 else 'article'
                 end
          { type: type, id: i }
        end
      end

      before do
        # Allow any calculate_target_positions call since we'll have multiple batches
        allow(distribution_calculator).to receive(:calculate_target_positions)
          .with(any_args)
          .and_return([]) # Return empty array for simplicity
      end

      it 'processes the collection in batches' do
        result

        # Verify distribution calculator was called for each type in each full batch
        full_batches = large_collection_size / batch_size
        remainder = large_collection_size % batch_size
        expected_calls = full_batches * 3 # 3 types per batch
        expected_calls += 3 if remainder > 0 # Add calls for remainder batch

        expect(distribution_calculator)
          .to have_received(:calculate_target_positions)
          .exactly(expected_calls).times
      end

      it 'maintains all items from the original collection' do
        expect(result.map { |item| item[:id] }.sort)
          .to eq((0...large_collection_size).to_a)
      end

      it 'maintains relative type distribution across batches' do
        type_counts = result.group_by { |item| item[:type] }
                            .transform_values(&:count)

        # Each type should be roughly 1/3 of the total
        type_counts.each_value do |count|
          ratio = count.to_f / large_collection_size
          expect(ratio).to be_within(0.1).of(1.0 / 3.0)
        end
      end
    end
  end
end
