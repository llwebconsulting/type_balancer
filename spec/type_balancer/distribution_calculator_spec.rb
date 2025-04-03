# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::DistributionCalculator do
  let(:calculator) { described_class.new }

  describe '#calculate_target_positions' do
    subject(:positions) { calculator.calculate_target_positions(total_count, available_items, target_ratio) }

    let(:total_count) { 10 }
    let(:available_items) { 4 }
    let(:target_ratio) { 0.4 }
    let(:expected_positions) { [0, 3, 6, 9] }

    before do
      allow(TypeBalancer::Distributor).to receive(:calculate_target_positions)
        .with(total_count, available_items, target_ratio)
        .and_return(expected_positions)
    end

    it 'delegates to the C extension' do
      expect(positions).to eq(expected_positions)
      expect(TypeBalancer::Distributor).to have_received(:calculate_target_positions)
        .with(total_count, available_items, target_ratio)
    end

    context 'when C extension raises an error' do
      before do
        allow(TypeBalancer::Distributor).to receive(:calculate_target_positions)
          .and_raise(TypeBalancer::Error, 'C extension error')
      end

      it 'propagates the error' do
        expect { positions }.to raise_error(TypeBalancer::Error, 'C extension error')
      end
    end

    context 'when arguments are nil' do
      let(:total_count) { nil }

      before do
        allow(TypeBalancer::Distributor).to receive(:calculate_target_positions)
          .and_raise(TypeError)
      end

      it 'raises a type error' do
        expect { positions }.to raise_error(TypeError)
      end
    end
  end
end
