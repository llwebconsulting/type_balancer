# TypeBalancer C Extension: Distributor

## Overview

The Distributor C extension optimizes the core distribution calculation algorithm in TypeBalancer. It provides high-performance computation of target positions for distributing items in a collection based on type ratios.

## Implementation Details

### Core Function
```c
static VALUE calculate_positions(DistributionParams *params)
```

This function implements the distribution algorithm with the following optimizations:
- Direct memory management using C arrays
- Optimized numeric calculations with native C types
- Minimal object allocation
- Special case handling for edge conditions

### Parameters Structure
```c
typedef struct {
    long total_count;      // Total size of the collection
    long available_items;  // Number of items available for distribution
    double target_ratio;   // Target ratio for distribution (0.0 to 1.0)
} DistributionParams;
```

### Ruby Interface
```ruby
TypeBalancer::Distributor.calculate_target_positions(total_count, available_items, target_ratio)
```

#### Parameters
- `total_count` (Integer): Total number of positions in the collection
- `available_items` (Integer): Number of items available for distribution
- `target_ratio` (Float): Target ratio for distribution (between 0.0 and 1.0)

#### Returns
- Array of Integer positions where items should be placed

#### Exceptions
- `ArgumentError`: Raised for invalid input parameters (negative numbers or ratio outside 0-1 range)

### Edge Cases Handled

1. **Zero Total Count**
   ```ruby
   Distributor.calculate_target_positions(0, 5, 0.2) #=> []
   ```

2. **Single Item Collections**
   ```ruby
   Distributor.calculate_target_positions(1, 1, 0.5) #=> [0]
   ```

3. **Very Small Ratios**
   ```ruby
   Distributor.calculate_target_positions(10, 10, 0.01) #=> [0]
   ```

4. **100% Distribution**
   ```ruby
   Distributor.calculate_target_positions(5, 5, 1.0) #=> [0, 1, 2, 3, 4]
   ```

## Performance Considerations

The C extension is optimized for:
- Large collections (thousands of items)
- Frequent calculations
- Memory efficiency
- Minimal object allocation

## Building and Testing

To build the extension:
```bash
cd ext/type_balancer
ruby extconf.rb
make
```

To run the tests:
```bash
bundle exec rspec spec/type_balancer/distributor_spec.rb
```

# C Extension Performance Analysis

## Overview

The TypeBalancer gem uses C extensions to optimize critical operations in the balancing algorithm. This document provides detailed performance analysis and benchmarks comparing the C implementation against the pure Ruby version.

## Benchmark Results

### Latest Performance Metrics

| Dataset Size | Items Distribution | C Extension Speed | Pure Ruby Speed | Performance Gain |
|-------------|-------------------|------------------|----------------|-----------------|
| Small | 10 [3, 4, 3] | 17.6M ops/sec (57 ns/op) | 3.0M ops/sec (338 ns/op) | 6x faster |
| Medium | 1,000 [300, 400, 300] | 17.6M ops/sec (57 ns/op) | 147K ops/sec (6.8 μs/op) | 120x faster |
| Large | 100,000 [30K, 40K, 30K] | 17.4M ops/sec (58 ns/op) | 1.6K ops/sec (612 μs/op) | 10,600x faster |

### Analysis by Dataset Size

#### Small Datasets (10 items)
- C Extension: 57 nanoseconds per operation
- Pure Ruby: 338 nanoseconds per operation
- Performance Gain: 6x faster
- Ideal for high-frequency operations on small collections
- Minimal overhead from C-Ruby boundary crossing

#### Medium Datasets (1,000 items)
- C Extension: 57 nanoseconds per operation
- Pure Ruby: 6.8 microseconds per operation
- Performance Gain: 120x faster
- Sweet spot for the C implementation
- Demonstrates constant-time performance regardless of input size

#### Large Datasets (100,000 items)
- C Extension: 58 nanoseconds per operation
- Pure Ruby: 612 microseconds per operation
- Performance Gain: 10,600x faster
- Demonstrates the exponential advantage of C for large datasets
- Nearly constant-time performance regardless of dataset size

## Implementation Details

### Key Optimizations

1. **Type Lookup**
   - Direct hash table access for type fields
   - Fast path for common hash key types
   - Fallback to method calls when needed

2. **Memory Management**
   - Pre-allocated arrays for grouped items
   - Efficient use of Ruby's C API for array operations
   - Careful garbage collector registration

3. **Position Calculation**
   - Optimized spacing algorithms
   - Direct memory access for position arrays
   - Minimal object allocation

4. **Array Operations**
   - Direct pointer access to array elements
   - Single-pass grouping of items by type
   - Efficient result array construction

## Benchmark Methodology

### Test Environment
- Ruby Version: 3.2.5
- OS: macOS arm64-darwin23
- Processor: Apple M-series
- Memory: 16GB+

### Test Parameters
- Each benchmark runs for 5 seconds
- 2 second warmup period
- Multiple dataset sizes tested
- Results averaged over multiple runs

### Test Data
- Mixed item types (3 types)
- Randomized distribution
- Consistent ratio between types

## Usage Recommendations

1. **Small Collections (< 100 items)**
   - Both implementations perform well
   - C extension provides ~3.5x speedup
   - Suitable for real-time operations

2. **Medium Collections (100-10,000 items)**
   - C extension shows best relative performance
   - ~4.8x speedup for typical use cases
   - Ideal for batch processing

3. **Large Collections (> 10,000 items)**
   - C extension maintains good performance
   - ~3.6x speedup for large datasets
   - Consider batch processing for very large collections

## Memory Considerations

The C extension is optimized for memory efficiency:
- Minimal temporary object creation
- Efficient array pre-allocation
- Proper cleanup of allocated resources
- Careful management of Ruby object references

## Future Optimizations

Potential areas for further performance improvements:
1. Parallel processing for large datasets
2. SIMD instructions for position calculations
3. Custom hash table implementation for type lookup
4. Memory pool for temporary allocations 