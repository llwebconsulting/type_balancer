# Detailed Documentation: `TypeBalancer.balance`

`TypeBalancer.balance` is the main method for distributing items of different types across a sequence, ensuring optimal spacing and respecting type ratios. It is highly configurable and supports custom type fields, type orderings, and different balancing strategies.

## Method Signature

```ruby
TypeBalancer.balance(items, type_field: :type, type_order: nil, strategy: nil, **strategy_options)
```

### Arguments
- `items` (Array<Hash>): The collection of items to balance. Each item should have a type field (default: `:type`).
- `type_field` (Symbol/String, optional): The key to use for extracting the type from each item. Default is `:type`.
- `type_order` (Array<String>, optional): An array specifying the desired order of types in the output. If omitted, the gem determines the order automatically.
- `strategy` (Symbol, optional): The balancing strategy to use. Default is `:sliding_window`.
- `strategy_options` (Hash, optional): Additional options specific to the chosen strategy.

## Available Strategies

### 1. Sliding Window Strategy (default)
The sliding window strategy is a sophisticated approach that balances items by examining fixed-size windows of items sequentially. For each window, it:
1. Calculates the target ratio of each type based on the overall collection
2. Ensures minimum representation of each type when possible
3. Distributes remaining slots to maintain target ratios
4. Handles transitions between windows to maintain smooth distribution

**Technical Details:**
- Default window size: 10 items
- Minimum representation: Each type gets at least one slot in a window if ratio > 0
- Ratio preservation: Maintains approximate global ratios while ensuring local diversity
- Adaptive sizing: Window size automatically adjusts near the end of the collection

**Configuration Options:**
```ruby
TypeBalancer.balance(items,
  strategy: :sliding_window,
  window_size: 25,        # Size of the sliding window
  type_field: :type,      # Field containing type information
  type_order: %w[...]     # Optional: preferred type order
)
```

**When to Use:**
1. **Content Feed Optimization**
   - Perfect for social media feeds, blog lists, or any paginated content
   - Ensures users see a diverse mix regardless of where they stop scrolling
   ```ruby
   TypeBalancer.balance(posts, 
     strategy: :sliding_window,
     window_size: 10
   )
   ```

2. **E-commerce Category Display**
   - Balances product types in search results or category pages
   - Maintains category ratios while ensuring variety
   ```ruby
   TypeBalancer.balance(products,
     strategy: :sliding_window,
     window_size: 15,
     type_field: :category
   )
   ```

3. **News Feed Management**
   - Mixes different news categories while maintaining importance
   - Larger windows allow for some natural clustering
   ```ruby
   TypeBalancer.balance(articles,
     strategy: :sliding_window,
     window_size: 25,
     type_order: %w[breaking featured regular]
   )
   ```

**Window Size Guidelines:**
- **Small (5-10 items)**
  - Strictest local balance
  - Best for: Short lists, critical diversity needs
  - Example: Featured content sections

- **Medium (15-25 items)**
  - Balanced local/global distribution
  - Best for: Standard content feeds
  - Example: Blog post listings

- **Large (30+ items)**
  - More gradual transitions
  - Best for: Long-form content, natural grouping
  - Example: Search results with category clustering

**Implementation Notes:**
- The strategy maintains a queue for each type
- Window calculations consider both used and available items
- Edge cases (end of collection, single type) are handled gracefully
- Performance scales linearly with collection size

**Example with Analysis:**
```ruby
# Balance a feed with analytics
items = [
  { type: 'video', id: 1 },
  { type: 'article', id: 2 },
  # ... more items
]

balanced = TypeBalancer.balance(items,
  strategy: :sliding_window,
  window_size: 15,
  type_field: :type
)

# Analyze distribution in first window
first_window = balanced.first(15)
distribution = first_window.group_by { |i| i[:type] }
                         .transform_values(&:count)
```

## Usage Examples

### 1. Basic Balancing (Default Strategy)
```ruby
items = [
  { type: 'video', title: 'Video 1' },
  { type: 'image', title: 'Image 1' },
  { type: 'article', title: 'Article 1' },
  { type: 'article', title: 'Article 2' },
  { type: 'image', title: 'Image 2' },
  { type: 'video', title: 'Video 2' }
]
balanced = TypeBalancer.balance(items)
# => [ { type: 'article', ... }, { type: 'image', ... }, { type: 'video', ... }, ... ]
```

### 2. Custom Strategy Options
```ruby
# Large window size for more gradual transitions
balanced = TypeBalancer.balance(items,
  strategy: :sliding_window,
  window_size: 50,
  type_order: %w[image video article]
)
```

### 3. Custom Type Field
```ruby
items = [
  { category: 'video', title: 'Video 1' },
  { category: 'image', title: 'Image 1' },
  { category: 'article', title: 'Article 1' }
]
balanced = TypeBalancer.balance(items, type_field: :category)
# => [ { category: 'article', ... }, { category: 'image', ... }, { category: 'video', ... } ]
```

### 4. Handling Missing Types
If a type in `type_order` is not present in the input, it is simply ignored in the output order.

### 5. Edge Cases
- **Empty Input:** Raises an exception (`Collection cannot be empty`).
- **Single Type:** All items are returned in their original order.
- **Missing Type Field:** If an item is missing the type field, it is ignored or may cause an error depending on context.

## Notes and Caveats
- The method is deterministic: the same input will always produce the same output.
- The `type_order` argument must be an array of strings matching the type values in your items.
- If you use a custom `type_field`, ensure all items have that field.
- The method does not mutate the input array.
- Strategy options are specific to each strategy and are ignored by other strategies.

## See Also
- [README.md](../README.md) for general usage
- [Quality Script Documentation](quality.md) for integration tests and examples
- [Detailed Position Calculation Documentation](calculate_positions.md) 