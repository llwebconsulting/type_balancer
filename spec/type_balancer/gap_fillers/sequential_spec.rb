# frozen_string_literal: true

require "spec_helper"

RSpec.describe TypeBalancer::GapFillers::Sequential do
  subject(:filler) { described_class.new(collection, items_arrays) }

  let(:size) { 10 }
  let(:collection) { Array.new(size) }
  let(:items_arrays) { [%w[A1 A2], %w[B1 B2], %w[C1 C2]] }

  describe "#fill_gaps" do
    context "with empty collection" do
      it "fills sequentially from each array" do
        result = filler.fill_gaps((0..5).to_a)
        expect(result[0..5]).to eq(%w[A1 B1 C1 A2 B2 C2])
      end

      it "handles arrays of different sizes" do
        arrays = [%w[A1 A2 A3], %w[B1], %w[C1 C2]]
        filler = described_class.new(collection, arrays)
        result = filler.fill_gaps((0..5).to_a)
        expect(result[0..5]).to eq(%w[A1 B1 C1 A2 C2 A3])
      end

      it "handles single array" do
        filler = described_class.new(collection, [%w[A1 A2 A3]])
        result = filler.fill_gaps((0..2).to_a)
        expect(result[0..2]).to eq(%w[A1 A2 A3])
      end
    end

    context "with existing items" do
      let(:collection) { [nil, "X", nil, nil, "Y", nil] }

      it "fills only nil positions sequentially from each array" do
        result = filler.fill_gaps([0, 2, 3, 5])
        expect(result).to eq(%w[A1 X B1 C1 Y A2])
      end

      it "handles arrays of different sizes" do
        arrays = [%w[A1 A2 A3], %w[B1], %w[C1 C2]]
        filler = described_class.new(collection, arrays)
        result = filler.fill_gaps([0, 2, 3, 5])
        expect(result).to eq(%w[A1 X B1 C1 Y A2])
      end

      it "handles single array" do
        filler = described_class.new(collection, [%w[A1 A2 A3]])
        result = filler.fill_gaps([0, 2, 3, 5])
        expect(result).to eq(["A1", "X", "A2", "A3", "Y", nil])
      end
    end

    context "with empty arrays" do
      it "returns original collection when all arrays are empty" do
        filler = described_class.new(collection, [[], [], []])
        result = filler.fill_gaps([0, 1, 2])
        expect(result).to eq([nil, nil, nil, nil, nil, nil, nil, nil, nil, nil])
      end

      it "skips empty arrays" do
        arrays = [[], %w[B1 B2], []]
        filler = described_class.new(collection, arrays)
        result = filler.fill_gaps([0, 1])
        expect(result[0..1]).to eq(%w[B1 B2])
      end

      it "handles empty array list" do
        filler = described_class.new(collection, [])
        result = filler.fill_gaps([0, 1, 2])
        expect(result).to eq([nil, nil, nil, nil, nil, nil, nil, nil, nil, nil])
      end
    end

    context "with nil arrays" do
      it "handles nil arrays in the list" do
        arrays = [%w[A1 A2], nil, %w[C1 C2]]
        filler = described_class.new(collection, arrays)
        result = filler.fill_gaps([0, 1, 2, 3])
        expect(result[0..3]).to eq(%w[A1 C1 A2 C2])
      end

      it "handles all nil arrays" do
        filler = described_class.new(collection, [nil, nil, nil])
        result = filler.fill_gaps([0, 1, 2])
        expect(result).to eq([nil, nil, nil, nil, nil, nil, nil, nil, nil, nil])
      end
    end
  end
end
