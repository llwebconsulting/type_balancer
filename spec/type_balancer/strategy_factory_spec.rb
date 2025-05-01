# frozen_string_literal: true

require 'spec_helper'
require 'type_balancer/strategies/base_strategy'
require 'type_balancer/strategies/sliding_window_strategy'
require 'type_balancer/strategy_factory'

RSpec.describe TypeBalancer::StrategyFactory do
  let(:dummy_strategy) do
    Class.new(TypeBalancer::Strategies::BaseStrategy) do
      def balance
        []
      end
    end
  end

  before do
    described_class.instance_variable_set(:@strategies, {})
    described_class.instance_variable_set(:@default_strategy, nil)
    described_class.register(:sliding_window, TypeBalancer::Strategies::SlidingWindowStrategy)
    described_class.default_strategy = :sliding_window
  end

  describe '.create' do
    let(:items) { [{ type: 'video' }, { type: 'image' }] }

    it 'creates strategy instance with default strategy when none specified' do
      strategy = described_class.create(items: items, type_field: :type)
      expect(strategy).to be_a(TypeBalancer::Strategies::SlidingWindowStrategy)
    end

    it 'creates strategy instance with specified strategy' do
      strategy = described_class.create(:sliding_window, items: items, type_field: :type)
      expect(strategy).to be_a(TypeBalancer::Strategies::SlidingWindowStrategy)
    end

    it 'raises error for unknown strategy' do
      expect { described_class.create(:unknown, items: items, type_field: :type) }
        .to raise_error(ArgumentError, 'Unknown strategy: unknown')
    end

    it 'passes options to strategy constructor' do
      strategy = described_class.create(:sliding_window, items: items, type_field: :type, window_size: 20)
      expect(strategy.instance_variable_get(:@window_size)).to eq(20)
    end
  end

  describe '.register' do
    let(:test_strategy) { Class.new(TypeBalancer::Strategies::BaseStrategy) }

    it 'registers new strategy' do
      described_class.register(:test, test_strategy)
      expect(described_class.send(:strategies)[:test]).to eq(test_strategy)
    end

    it 'overwrites existing strategy' do
      described_class.register(:test, test_strategy)
      new_strategy = Class.new(TypeBalancer::Strategies::BaseStrategy)
      described_class.register(:test, new_strategy)
      expect(described_class.send(:strategies)[:test]).to eq(new_strategy)
    end
  end

  describe '.default_strategy=' do
    let(:test_strategy) { Class.new(TypeBalancer::Strategies::BaseStrategy) }

    it 'sets default strategy' do
      described_class.register(:test, test_strategy)
      described_class.default_strategy = :test
      expect(described_class.default_strategy).to eq(:test)
    end

    it 'raises error for unknown strategy' do
      expect { described_class.default_strategy = :unknown }
        .to raise_error(ArgumentError, 'Unknown strategy: unknown')
    end
  end

  describe '.default_strategy' do
    it 'returns sliding_window by default' do
      expect(described_class.default_strategy).to eq(:sliding_window)
    end

    it 'returns set default strategy' do
      test_strategy = Class.new(TypeBalancer::Strategies::BaseStrategy)
      described_class.register(:test, test_strategy)
      described_class.default_strategy = :test
      expect(described_class.default_strategy).to eq(:test)
    end
  end
end
