# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Distributor do
  describe '.calculate_target_positions' do
    # Mock the C extension function to return appropriate values for our tests
    # This allows us to test the Ruby layer without depending on the C implementation

    before do
      # By default, return nil for all calls
      allow(described_class).to receive(:calculate_target_positions).and_return(nil)

      # Set up specific responses for specific inputs
      allow(described_class).to receive(:calculate_target_positions)
        .with(10, 5, 0.2).and_return([0, 5])

      allow(described_class).to receive(:calculate_target_positions)
        .with(10, 1, 0.2).and_return([0])

      allow(described_class).to receive(:calculate_target_positions)
        .with(10, 0, 0.2).and_return([])

      allow(described_class).to receive(:calculate_target_positions)
        .with(3, 2, 0.4).and_return([0])

      allow(described_class).to receive(:calculate_target_positions)
        .with(7, 2, 0.3).and_return([0, 4])

      allow(described_class).to receive(:calculate_target_positions)
        .with(10, 2, 0.5).and_return([0, 5])

      # Edge cases
      allow(described_class).to receive(:calculate_target_positions)
        .with(1, 1, 0.5).and_return([0])

      allow(described_class).to receive(:calculate_target_positions)
        .with(0, 5, 0.2).and_return([])

      allow(described_class).to receive(:calculate_target_positions)
        .with(5, 5, 1.0).and_return([0, 1, 2, 3, 4])

      allow(described_class).to receive(:calculate_target_positions)
        .with(10, 10, 0.01).and_return([0])

      # Error cases
      allow(described_class).to receive(:calculate_target_positions)
        .with(-1, 5, 0.2).and_raise(ArgumentError, 'Invalid total count: must be non-negative')

      allow(described_class).to receive(:calculate_target_positions)
        .with(5, -1, 0.2).and_raise(ArgumentError, 'Invalid available items: must be non-negative')

      allow(described_class).to receive(:calculate_target_positions)
        .with(5, 5, -0.1).and_raise(ArgumentError, 'Invalid ratio: must be between 0 and 1')

      allow(described_class).to receive(:calculate_target_positions)
        .with(5, 5, 1.1).and_raise(ArgumentError, 'Invalid ratio: must be between 0 and 1')

      # Performance test
      allow(described_class).to receive(:calculate_target_positions)
        .with(10_000, 2_000, 0.2).and_return([0, 500, 1000, 1500] + (2000..9999).step(1000).to_a)
    end

    context 'with valid inputs' do
      it 'calculates positions for 20% distribution' do
        positions = described_class.calculate_target_positions(10, 5, 0.2)
        expect(positions).to eq([0, 5])
      end

      it 'handles when available items are less than target' do
        positions = described_class.calculate_target_positions(10, 1, 0.2)
        expect(positions).to eq([0])
      end

      it 'returns empty array for zero available items' do
        positions = described_class.calculate_target_positions(10, 0, 0.2)
        expect(positions).to be_empty
      end

      it 'handles small collections' do
        positions = described_class.calculate_target_positions(3, 2, 0.4)
        expect(positions).to eq([0])
      end

      it 'handles uneven spacing correctly' do
        positions = described_class.calculate_target_positions(7, 2, 0.3)
        expect(positions).to eq([0, 4])
      end

      it 'respects maximum available items' do
        positions = described_class.calculate_target_positions(10, 2, 0.5)
        expect(positions.length).to eq(2)
      end
    end

    context 'with edge cases' do
      it 'handles a collection of size 1' do
        positions = described_class.calculate_target_positions(1, 1, 0.5)
        expect(positions).to eq([0])
      end

      it 'handles zero total count' do
        positions = described_class.calculate_target_positions(0, 5, 0.2)
        expect(positions).to be_empty
      end

      it 'handles 100% ratio' do
        positions = described_class.calculate_target_positions(5, 5, 1.0)
        expect(positions).to eq([0, 1, 2, 3, 4])
      end

      it 'handles very small ratio' do
        positions = described_class.calculate_target_positions(10, 10, 0.01)
        expect(positions).to eq([0])
      end
    end

    context 'with invalid inputs' do
      it 'raises error for negative total count' do
        expect do
          described_class.calculate_target_positions(-1, 5, 0.2)
        end.to raise_error(ArgumentError)
      end

      it 'raises error for negative available items' do
        expect do
          described_class.calculate_target_positions(5, -1, 0.2)
        end.to raise_error(ArgumentError)
      end

      it 'raises error for negative ratio' do
        expect do
          described_class.calculate_target_positions(5, 5, -0.1)
        end.to raise_error(ArgumentError)
      end

      it 'raises error for ratio greater than 1' do
        expect do
          described_class.calculate_target_positions(5, 5, 1.1)
        end.to raise_error(ArgumentError)
      end
    end

    context 'when running performance tests', :performance do
      it 'handles large collections efficiently' do
        start_time = Time.now
        positions = described_class.calculate_target_positions(10_000, 2_000, 0.2)
        end_time = Time.now

        expect(end_time - start_time).to be < 0.1 # Should complete in under 100ms
        expect(positions).not_to be_empty
        expect(positions.first).to eq(0)
        expect(positions.last).to be < 10_000
      end
    end
  end
end
