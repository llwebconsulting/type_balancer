# frozen_string_literal: true

require "spec_helper"

RSpec.describe TypeBalancer::GapFillers::Base do
  subject(:filler) { described_class.new(collection) }

  let(:collection) { Array.new(5) }

  describe "#fill_gaps" do
    it "raises NotImplementedError" do
      expect { filler.fill_gaps([0, 1, 2]) }.to raise_error(NotImplementedError)
    end
  end
end
