# frozen_string_literal: true

require "spec_helper"

RSpec.describe TypeBalancer::OrderedCollectionManager do
  subject(:manager) { described_class.new(size) }

  let(:size) { 10 }

  describe "#place_at_positions" do
    let(:manager) { described_class.new(5) }
    let(:items) { %w[A B C] }
    let(:positions) { [1, 3, 4] }

    it "places items at specified positions" do
      manager.place_at_positions(items, positions)
      expect(manager.result).to eq(%w[A B C])
    end

    it "places items in sequence" do
      manager.place_at_positions(items, positions)
      expect(manager.result).to eq(%w[A B C])
    end

    context "with more positions than items" do
      let(:positions) { [0, 2, 4, 5] }

      it "fills available positions" do
        manager.place_at_positions(items, positions)
        expect(manager.result).to eq(%w[A B C])
      end

      it "leaves extra positions as nil" do
        manager.place_at_positions(items, positions)
        expect(manager.result).to eq(%w[A B C])
      end
    end

    context "with more items than positions" do
      let(:items) { %w[A B C D E] }
      let(:positions) { [1, 3] }

      it "uses only the needed items" do
        manager.place_at_positions(items, positions)
        expect(manager.result).to eq(%w[A B])
      end

      it "ignores extra items" do
        manager.place_at_positions(items, positions)
        expect(manager.result).to eq(%w[A B])
      end
    end
  end

  describe "#fill_gaps_alternating" do
    let(:manager) { described_class.new(6) }
    let(:primary_items) { %w[A B C] }
    let(:secondary_items) { %w[X Y Z] }

    context "with empty positions" do
      before do
        manager.place_at_positions(%w[1], [2])
      end

      it "fills first gap with primary item" do
        manager.fill_gaps_alternating(primary_items, secondary_items)
        expect(manager.result).to include("A")
      end

      it "fills second gap with secondary item" do
        manager.fill_gaps_alternating(primary_items, secondary_items)
        expect(manager.result).to include("X")
      end

      it "alternates between primary and secondary items" do
        manager.fill_gaps_alternating(primary_items, secondary_items)
        expect(manager.result).to include("B", "Y")
      end
    end

    context "when one type runs out" do
      let(:primary_items) { %w[A] }
      let(:secondary_items) { %w[X Y Z] }

      it "continues with available secondary items" do
        manager.fill_gaps_alternating(primary_items, secondary_items)
        expect(manager.result).to eq(%w[A X Y Z])
      end
    end
  end

  describe "#fill_remaining_gaps" do
    let(:manager) { described_class.new(6) }
    let(:items_arrays) { [%w[A B], %w[X Y], %w[1 2]] }

    context "with empty positions" do
      before do
        manager.place_at_positions(%w[Q], [3])
      end

      it "fills first gaps with first array" do
        manager.fill_remaining_gaps(items_arrays)
        expect(manager.result).to include("A", "B")
      end

      it "fills next gaps with second array" do
        manager.fill_remaining_gaps(items_arrays)
        expect(manager.result).to include("X", "Y")
      end

      it "fills remaining gaps with third array" do
        manager.fill_remaining_gaps(items_arrays)
        expect(manager.result).to include("1")
      end
    end
  end

  describe "#result" do
    it "returns only non-nil elements" do
      manager.place_at_positions(%w[A B], [0, 2])
      expect(manager.result).to eq(%w[A B])
    end

    it "preserves order of placed items" do
      manager.place_at_positions(%w[A B C], [2, 0, 1])
      expect(manager.result).to eq(%w[A B C])
    end

    it "returns empty array when no items placed" do
      expect(manager.result).to be_empty
    end
  end
end
