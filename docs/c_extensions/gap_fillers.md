# TypeBalancer C Extension: Gap Fillers

## Overview

The Gap Fillers C extensions optimize the process of filling empty positions in a collection. These extensions replace Ruby implementations with highly optimized C code, providing significant performance improvements, especially for large collections.

## Modules

The Gap Fillers functionality consists of two main modules:

1. **SequentialFiller**: Fills gaps by cycling through available item arrays
2. **AlternatingFiller**: Fills gaps by alternating between primary and secondary items

## Implementation Details

### Sequential Filler Context

```c
typedef struct {
    VALUE collection;          // The collection to fill
    VALUE items_arrays;        // Arrays of items to use for filling
    long current_array;        // Current array index
    long current_index;        // Current index within the current array
} sequential_filler_context;
```

The SequentialFiller efficiently fills empty positions using a round-robin approach:
- Maintains state about current array and index positions
- Uses round-robin array selection for balanced distribution
- Proper memory management with garbage collector awareness
- Efficient nil checking and position validation

#### Ruby Interface

```ruby
TypeBalancer::SequentialFiller.fill(collection, positions, items_arrays)
```

##### Parameters
- `collection` (Array): The collection with gaps to fill
- `positions` (Array): The positions to fill (typically empty positions)
- `items_arrays` (Array): Arrays of items to use for filling positions

##### Returns
- A new array with gaps filled in round-robin order from the provided items arrays
- Returns nil if any input validation fails

### Alternating Filler Context

```c
typedef struct {
    VALUE collection;          // The collection to fill
    VALUE primary_items;       // Primary items array
    VALUE secondary_items;     // Secondary items array
    long current_array;        // Current array index (0 for primary, 1 for secondary)
    long current_index;        // Current index within the current array
} alternating_filler_context;
```

The AlternatingFiller efficiently fills empty positions by alternating between two sets of items:
- Maintains separate tracking for primary and secondary items
- Alternates between arrays as it fills positions
- Falls back to available array when one is depleted
- Efficient nil checking and position validation

#### Ruby Interface

```ruby
TypeBalancer::AlternatingFiller.fill(collection, positions, primary_items, secondary_items)
```

##### Parameters
- `collection` (Array): The collection with gaps to fill
- `positions` (Array): The positions to fill (typically empty positions)
- `primary_items` (Array): Primary items to use (for even gaps)
- `secondary_items` (Array): Secondary items to use (for odd gaps)

##### Returns
- A new array with gaps filled alternating between primary and secondary items
- Returns nil if any input validation fails

## Memory Management

Both fillers implement careful memory management:

1. **Garbage Collection Registration**
   - All Ruby objects are properly registered with the GC
   - Context structures are marked for GC tracking
   - Arrays are protected from GC during operations

2. **Memory Safety**
   - Input validation prevents buffer overflows
   - Proper cleanup in error conditions
   - Safe handling of nil values

3. **Performance Optimization**
   - Minimal object allocation
   - Direct array access where possible
   - Efficient position tracking

## Error Handling

Both fillers implement robust error handling:

1. **Input Validation**
   - Check for nil inputs
   - Validate array types
   - Verify position bounds
   - Ensure collection is not empty

2. **Operation Safety**
   - Handle array bounds gracefully
   - Skip invalid positions
   - Return nil on critical errors

## Example Usage

```ruby
# Using SequentialFiller
collection = Array.new(10)
positions = [0, 1, 2, 5, 7, 9]
items_arrays = [['A1', 'A2'], ['B1', 'B2'], ['C1', 'C2']]
result = TypeBalancer::SequentialFiller.fill(collection, positions, items_arrays)
# result = ['A1', 'B1', 'C1', nil, nil, 'A2', nil, 'B2', nil, 'C2']

# Using AlternatingFiller
collection = Array.new(10)
positions = [0, 1, 2, 5, 7, 9]
primary = ['P1', 'P2', 'P3']
secondary = ['S1', 'S2', 'S3']
result = TypeBalancer::AlternatingFiller.fill(collection, positions, primary, secondary)
# result = ['P1', 'S1', 'P2', nil, nil, 'S2', nil, 'P3', nil, 'S3']
```

## Building and Testing

The gap fillers are built as part of the main gem:

```bash
bundle exec rake compile
```

Testing is handled through RSpec integration tests:

```bash
bundle exec rspec
```

The tests verify:
- Proper filling of gaps
- Handling of edge cases
- Memory safety
- Error conditions
- Integration with Ruby code 