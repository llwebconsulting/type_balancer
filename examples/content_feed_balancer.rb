# frozen_string_literal: true

require 'type_balancer'

# Basic example with a custom class
class Item
  attr_reader :type, :name

  def initialize(type, name)
    @type = type
    @name = name
  end
end

# Example usage with objects
items = [
  Item.new('video', 'Video 1'),
  Item.new('video', 'Video 2'),
  Item.new('image', 'Image 1'),
  Item.new('image', 'Image 2'),
  Item.new('image', 'Image 3'),
  Item.new('article', 'Article 1')
]

# Get balanced items
TypeBalancer::Balancer.new(items, type_field: :type).call

# Example with hashes
hash_items = [
  { type: 'video', name: 'Video 1' },
  { type: 'video', name: 'Video 2' },
  { type: 'image', name: 'Image 1' },
  { type: 'image', name: 'Image 2' },
  { type: 'article', name: 'Article 1' }
]

# Get balanced hash items
TypeBalancer::Balancer.new(hash_items, type_field: :type).call

# Real-world example: Content Feed Balancer
class ContentFeedBalancer
  def initialize(content_items)
    @content_items = content_items
  end

  def call
    return [] if @content_items.empty?
    return @content_items if single_content_type?

    balancer = TypeBalancer::Balancer.new(
      @content_items,
      type_field: :content_type,
      types: %w[video image article] # Prioritize videos, then images, then articles
    )
    balancer.call
  end

  private

  def single_content_type?
    @content_items.map(&:content_type).uniq.size == 1
  end
end

# Example usage with a Struct for demonstration
ContentItem = Struct.new(:content_type, :title, keyword_init: true)

content = [
  ContentItem.new(content_type: 'video', title: 'How-to Guide'),
  ContentItem.new(content_type: 'image', title: 'Product Showcase'),
  ContentItem.new(content_type: 'article', title: 'Technical Deep Dive'),
  ContentItem.new(content_type: 'video', title: 'Customer Story'),
  ContentItem.new(content_type: 'image', title: 'Infographic')
]

# Get balanced content
ContentFeedBalancer.new(content).call

# Rails Integration Example
if defined?(Rails)
  # app/models/content_item.rb
  class ContentItem < ApplicationRecord
    # Assuming content_type is a column in your database
    validates :content_type, presence: true,
                             inclusion: { in: %w[video image article] }
  end

  # app/services/feed_balancer_service.rb
  class FeedBalancerService
    def initialize(content_items)
      @content_items = content_items
    end

    def balanced_feed
      TypeBalancer::Balancer.new(
        @content_items,
        type_field: :content_type,
        types: %w[video image article]
      ).call
    end
  end

  # app/controllers/feeds_controller.rb
  class FeedsController < ApplicationController
    def index
      content_items = ContentItem.all
      @balanced_feed = FeedBalancerService.new(content_items).balanced_feed
    end
  end
end
