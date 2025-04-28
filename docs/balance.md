# Detailed Documentation: `TypeBalancer.balance`

`TypeBalancer.balance` is the main method for distributing items of different types across a sequence, ensuring optimal spacing and respecting type ratios. It is highly configurable and supports custom type fields and type orderings.

## Method Signature

```ruby
TypeBalancer.balance(items, type_field: :type, type_order: nil)
```

### Arguments
- `items` (Array<Hash>): The collection of items to balance. Each item should have a type field (default: `:type`).
- `type_field` (Symbol/String, optional): The key to use for extracting the type from each item. Default is `:type`.
- `type_order` (Array<String>, optional): An array specifying the desired order of types in the output. If omitted, the gem determines the order automatically.

## Return Value
- Returns a new array of items, balanced by type and spaced as evenly as possible.
- The output array will have the same length as the input.

## Usage Examples

### 1. Basic Balancing
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

### 2. Custom Type Order
```ruby
# Prioritize images, then videos, then articles
balanced = TypeBalancer.balance(items, type_order: %w[image video article])
# => [ { type: 'image', ... }, { type: 'video', ... }, { type: 'article', ... }, ... ]
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

## See Also
- [README.md](../README.md) for general usage
- [Quality Script Documentation](quality.md) for integration tests and examples
- [Detailed Position Calculation Documentation](calculate_positions.md) 