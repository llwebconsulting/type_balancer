# Detailed Documentation: `TypeBalancer.calculate_positions`

`TypeBalancer.calculate_positions` is a utility method for determining the optimal positions for a given number of items (or a ratio of items) within a sequence of slots. This is useful for advanced scenarios where you want to control the distribution of a specific type or subset of items.

## Method Signature

```ruby
TypeBalancer.calculate_positions(total_count:, ratio:, available_items: nil)
```

### Arguments
- `total_count` (Integer): The total number of slots in the sequence (e.g., the length of your feed or array).
- `ratio` (Float): The desired ratio of items to place (e.g., `0.3` for 30%).
- `available_items` (Array<Integer>, optional): An array of slot indices where placement is allowed. If omitted, all slots are considered available.

## Return Value
- Returns an array of integer indices representing the optimal positions for the items.
- The array will have a length close to `total_count * ratio`, rounded as appropriate.
- If `available_items` is provided, only those slots will be used.

## Usage Examples

### 1. Even Distribution
```ruby
# Place 3 items evenly in 10 slots
TypeBalancer.calculate_positions(total_count: 10, ratio: 0.3)
# => [0, 5, 9]
```

### 2. Restricting to Available Slots
```ruby
# Only use slots 0, 1, and 2
TypeBalancer.calculate_positions(total_count: 10, ratio: 0.5, available_items: [0, 1, 2])
# => [0, 1, 2]
```

### 3. Edge Cases
```ruby
# Single item
TypeBalancer.calculate_positions(total_count: 1, ratio: 1.0)
# => [0]

# No items
TypeBalancer.calculate_positions(total_count: 100, ratio: 0.0)
# => []

# All items
TypeBalancer.calculate_positions(total_count: 5, ratio: 1.0)
# => [0, 1, 2, 3, 4]
```

### 4. Precision with Small Ratios
```ruby
# Two positions in three slots
TypeBalancer.calculate_positions(total_count: 3, ratio: 0.67)
# => [0, 1]

# Single position in three slots
TypeBalancer.calculate_positions(total_count: 3, ratio: 0.34)
# => [0]
```

### 5. Available Items Edge Cases
```ruby
# Single target with multiple available positions
TypeBalancer.calculate_positions(total_count: 5, ratio: 0.2, available_items: [1, 2, 3])
# => [1]

# Two targets with multiple available positions
TypeBalancer.calculate_positions(total_count: 10, ratio: 0.2, available_items: [1, 3, 5])
# => [1, 5]

# Exact match of available positions
TypeBalancer.calculate_positions(total_count: 10, ratio: 0.3, available_items: [2, 4, 6])
# => [2, 4, 6]
```

## Notes and Caveats
- If `ratio` is 0 or `total_count` is 0, returns an empty array.
- If `ratio` is 1.0, returns all available slots.
- If `available_items` is provided and its length is less than the target count, all available items are returned.
- For very small or very large ratios, the method ensures at least one or all slots are used, respectively.
- The method is deterministic and will always return the same result for the same input.

## See Also
- [README.md](../README.md) for general usage
- [Quality Script Documentation](quality.md) for integration tests and examples 