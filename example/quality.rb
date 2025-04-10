# frozen_string_literal: true

require 'type_balancer'

# This file serves as an example of how to use TypeBalancer
# You can run it directly in IRB to see how the balancing works

# Example 1: Basic Distribution
# Distribute 3 videos across 10 items
positions = TypeBalancer.calculate_positions(total_count: 10, ratio: 0.3)
puts "\nBasic Distribution Example:"
puts "Positions for 3 items across 10 slots: #{positions.inspect}"
puts "Spacing between positions: #{positions&.each_cons(2)&.map { |a, b| b - a }&.inspect}"

# Example 2: Working with Available Items
# Try to distribute 5 videos but only 3 slots are available
positions = TypeBalancer.calculate_positions(
  total_count: 10,
  ratio: 0.5,
  available_items: [0, 1, 2] # Specify actual available positions
)
puts "\nAvailable Items Example:"
puts "Positions when only 3 slots available: #{positions.inspect}"

# Example 3: Edge Cases
puts "\nEdge Cases:"
puts "Single item: #{TypeBalancer.calculate_positions(total_count: 1, ratio: 1.0).inspect}"
puts "No items needed: #{TypeBalancer.calculate_positions(total_count: 100, ratio: 0.0).inspect}"
puts "All items needed: #{TypeBalancer.calculate_positions(total_count: 5, ratio: 1.0).inspect}"

# Example 4: Real World Example - Content Feed
puts "\nReal World Example - Content Feed:"
feed_size = 20

# Calculate positions for different content types
content_positions = {
  video: TypeBalancer.calculate_positions(
    total_count: feed_size,
    ratio: 0.3, # 30% videos
    available_items: (0..7).to_a # 8 video positions available
  ),
  image: TypeBalancer.calculate_positions(
    total_count: feed_size,
    ratio: 0.4, # 40% images
    available_items: (0..14).to_a # 15 image positions available
  ),
  article: TypeBalancer.calculate_positions(
    total_count: feed_size,
    ratio: 0.3 # 30% articles
  )
}

puts "\nContent Type Positions:"
content_positions.each do |type, pos|
  puts "#{type}: #{pos.inspect}"
end

# Verify no overlaps
all_positions = content_positions.values.compact.flatten
if all_positions == all_positions.uniq
  puts "\nSuccess: No overlapping positions!"
else
  puts "\nWarning: Some positions overlap!"
end

# Show distribution
puts "\nDistribution Stats:"
content_positions.each do |type, positions|
  count = positions&.length || 0
  percentage = (count.to_f / feed_size * 100).round(1)
  puts "#{type}: #{count} items (#{percentage}% of feed)"
end
