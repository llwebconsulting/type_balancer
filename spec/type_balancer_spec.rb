# frozen_string_literal: true

RSpec.describe TypeBalancer do
  it "has a version number" do
    expect(TypeBalancer::VERSION).not_to be_nil
  end

  describe ".balance" do
    let(:items) do
      [
        { type: "video", name: "Video 1" },
        { type: "image", name: "Image 1" },
        { type: "strip", name: "Strip 1" },
        { type: "video", name: "Video 2" },
        { type: "image", name: "Image 2" },
        { type: "strip", name: "Strip 2" }
      ]
    end

    context "with default settings" do
      subject(:balanced_items) { described_class.balance(items) }

      it "preserves all items" do
        expect(balanced_items.size).to eq(items.size)
        expect(balanced_items).to match_array(items)
      end

      it "starts with a video item" do
        expect(balanced_items.first[:type]).to eq("video")
      end

      it "includes video items" do
        types = balanced_items.map { |item| item[:type] }
        expect(types.count("video")).to be > 0
      end

      it "includes image items" do
        types = balanced_items.map { |item| item[:type] }
        expect(types.count("image")).to be > 0
      end

      it "includes strip items" do
        types = balanced_items.map { |item| item[:type] }
        expect(types.count("strip")).to be > 0
      end
    end

    context "with custom type order" do
      subject(:balanced_items) { described_class.balance(items, type_order: %w[strip image video]) }

      it "preserves all items" do
        expect(balanced_items.size).to eq(items.size)
        expect(balanced_items).to match_array(items)
      end

      it "starts with a strip item" do
        expect(balanced_items.first[:type]).to eq("strip")
      end

      it "follows the custom type order" do
        types = balanced_items.map { |item| item[:type] }
        first_three_types = types[0..2]
        expect(first_three_types).to eq(%w[strip image video])
      end
    end

    context "with custom type field" do
      subject(:balanced_items) { described_class.balance(items, type_field: :category) }

      let(:test_item_class) { Struct.new(:category, :name) }
      let(:items) do
        [
          test_item_class.new("video", "Video 1"),
          test_item_class.new("image", "Image 1"),
          test_item_class.new("strip", "Strip 1")
        ]
      end

      it "preserves all items" do
        expect(balanced_items.size).to eq(items.size)
        expect(balanced_items).to match_array(items)
      end

      it "uses the custom type field for distribution" do
        types = balanced_items.map(&:category)
        expect(types).to eq(%w[video image strip])
      end
    end
  end
end
