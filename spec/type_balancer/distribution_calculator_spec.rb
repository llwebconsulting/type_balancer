# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::DistributionCalculator do
  subject(:calculator) { described_class.new(target_ratio) }

  let(:target_ratio) { 0.2 }

  describe '#calculate_target_positions' do
    context 'with default target ratio (0.2)' do
      it 'calculates positions for 20% of total' do
        positions = calculator.calculate_target_positions(10, 5)
        expect(positions.size).to eq(2) # 20% of 10 = 2
      end

      it 'spaces positions evenly' do
        positions = calculator.calculate_target_positions(10, 5)
        expect(positions).to eq([0, 5])
      end

      it 'handles when available items are less than target' do
        positions = calculator.calculate_target_positions(10, 1)
        expect(positions).to eq([0])
      end

      it 'handles zero available items' do
        positions = calculator.calculate_target_positions(10, 0)
        expect(positions).to be_empty
      end

      it 'handles small collections' do
        positions = calculator.calculate_target_positions(3, 2)
        expect(positions).to eq([0])
      end

      it 'handles uneven spacing correctly' do
        # With total_count = 7 and target_count = 2
        # spacing will be ceil(7/2) = 4
        # This should trigger the break condition when current_pos >= total_count
        positions = calculator.calculate_target_positions(7, 2)
        expect(positions).to eq([0, 4])
      end
    end

    context 'with custom target ratio' do
      let(:target_ratio) { 0.5 }

      it 'calculates positions based on custom ratio' do
        positions = calculator.calculate_target_positions(10, 5)
        expect(positions.size).to eq(5) # 50% of 10 = 5
      end

      it 'spaces positions evenly' do
        positions = calculator.calculate_target_positions(10, 5)
        expect(positions).to eq([0, 2, 4, 6, 8])
      end

      it 'handles when available items are less than target' do
        positions = calculator.calculate_target_positions(10, 2)
        expect(positions).to eq([0, 5])
      end
    end

    context 'with edge cases' do
      it 'handles a collection of size 1' do
        positions = calculator.calculate_target_positions(1, 1)
        expect(positions).to eq([0])
      end

      it 'handles zero total count' do
        positions = calculator.calculate_target_positions(0, 5)
        expect(positions).to be_empty
      end

      it 'handles when target ratio would result in zero positions' do
        calculator = described_class.new(0.1)
        positions = calculator.calculate_target_positions(5, 5)
        expect(positions).to eq([0])
      end
    end

    context 'when target count would result in positions beyond total count' do
      let(:total_count) { 5 }
      let(:available_items_count) { 3 }
      let(:target_ratio) { 0.5 } # This will make target_count = 3

      it 'stops adding positions when reaching total count' do
        expect(calculator.calculate_target_positions(total_count, available_items_count)).to eq([0, 2, 4])
      end
    end

    context 'when target count would exceed total count' do
      let(:total_count) { 3 }
      let(:available_items_count) { 5 }
      let(:target_ratio) { 0.9 } # This will make target_count = 3 and spacing = 1

      it 'stops adding positions at total count' do
        expect(calculator.calculate_target_positions(total_count, available_items_count)).to eq([0, 1, 2])
      end
    end

    context 'when current position equals total count' do
      let(:total_count) { 2 }
      let(:available_items_count) { 2 }
      let(:target_ratio) { 1.0 } # This will make target_count = 2 and spacing = 1

      it 'stops adding positions at total count' do
        expect(calculator.calculate_target_positions(total_count, available_items_count)).to eq([0, 1])
      end
    end

    context 'when current position exceeds total count' do
      let(:total_count) { 2 }
      let(:available_items_count) { 3 }
      let(:target_ratio) { 1.0 } # This will make target_count = 2 and spacing = 1

      it 'stops adding positions when reaching total count' do
        expect(calculator.calculate_target_positions(total_count, available_items_count)).to eq([0, 1])
      end
    end

    context 'when spacing would cause current_pos to exceed total_count' do
      let(:total_count) { 3 }
      let(:available_items_count) { 2 }
      let(:target_ratio) { 0.67 } # This will make target_count = 2 and spacing = 2

      it 'stops adding positions when current_pos would exceed total_count' do
        expect(calculator.calculate_target_positions(total_count, available_items_count)).to eq([0, 2])
      end

      it 'handles when current_pos equals total_count' do
        allow_any_instance_of(described_class).to receive(:calculate_target_count).and_return(2)
        allow_any_instance_of(described_class).to receive(:calculate_distributed_positions).and_call_original
        expect(calculator.calculate_target_positions(total_count, available_items_count)).to eq([0, 2])
      end
    end

    context 'when spacing would cause current_pos to exceed total_count immediately' do
      let(:total_count) { 2 }
      let(:available_items_count) { 2 }
      let(:target_ratio) { 0.5 } # This will make target_count = 1 and spacing = 2

      it 'breaks the loop when current_pos >= total_count' do
        expect(calculator.calculate_target_positions(total_count, available_items_count)).to eq([0])
      end
    end

    context 'when target_count is zero' do
      let(:total_count) { 2 }
      let(:available_items_count) { 0 }
      let(:target_ratio) { 0.5 } # This will make target_count = 0

      it 'returns an empty array' do
        expect(calculator.calculate_target_positions(total_count, available_items_count)).to eq([])
      end
    end

    context 'when current_pos would exceed total_count' do
      let(:total_count) { 1 }
      let(:available_items_count) { 2 }
      let(:target_ratio) { 1.0 } # This will make target_count = 1 and spacing = 1

      it 'stops adding positions when current_pos would exceed total_count' do
        expect(calculator.calculate_target_positions(total_count, available_items_count)).to eq([0])
      end
    end
  end
end
