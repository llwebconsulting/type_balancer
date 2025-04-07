# Benchmark Documentation

This document provides detailed information about TypeBalancer's performance benchmarks, including methodology, environment setup, and comprehensive results across different Ruby versions.

## Methodology

### Test Environment

- Hardware: ARM64 (aarch64) Linux environment
- Ruby Versions:
  - Ruby 3.2.8
  - Ruby 3.3.7
  - Ruby 3.4.2
- YJIT: Both enabled and disabled configurations tested
- Docker containers used for consistent testing environment

### Test Scenarios

Each benchmark test includes three dataset sizes:

1. Small Dataset:
   - Total Items: 10
   - Available Items: 5
   - Distribution Ratio: 0.2 (20%)

2. Medium Dataset:
   - Total Items: 1,000
   - Available Items: 200
   - Distribution Ratio: 0.2 (20%)

3. Large Dataset:
   - Total Items: 100,000
   - Available Items: 20,000
   - Distribution Ratio: 0.2 (20%)

### Measurement Approach

- Each test scenario is run multiple times to ensure statistical significance
- Both wall-clock time and CPU time are measured
- Results include operations per second and time per operation
- Benchmark-ips gem used for iterations per second calculations
- Both C Extension and Pure Ruby implementations tested under identical conditions

## Detailed Results

### Ruby 3.4.2 Performance

#### With YJIT Enabled

| Metric | Small Dataset | Medium Dataset | Large Dataset |
|--------|--------------|----------------|---------------|
| C Extension Speed | 25.8M ops/sec | 23.0M ops/sec | 26.5M ops/sec |
| C Extension Time/Op | 38.7 ns | 43.5 ns | 37.7 ns |
| Pure Ruby Speed | 3.8M ops/sec | 234K ops/sec | 3.0K ops/sec |
| Pure Ruby Time/Op | 260 ns | 4.3 μs | 331.8 μs |
| Performance Gain | 6.7x | 98.2x | 8,802x |

### Ruby 3.3.7 Performance

#### With YJIT Enabled

| Metric | Small Dataset | Medium Dataset | Large Dataset |
|--------|--------------|----------------|---------------|
| C Extension Speed | 28.1M ops/sec | 18.5M ops/sec | 26.9M ops/sec |
| C Extension Time/Op | 35.6 ns | 54.0 ns | 37.2 ns |
| Pure Ruby Speed | 3.3M ops/sec | 109K ops/sec | 1.6K ops/sec |
| Pure Ruby Time/Op | 305.3 ns | 9.2 μs | 636.4 μs |
| Performance Gain | 8.6x | 170x | 17,107x |

### Ruby 3.2.8 Performance

#### With YJIT Enabled

| Metric | Small Dataset | Medium Dataset | Large Dataset |
|--------|--------------|----------------|---------------|
| C Extension Speed | 13.4M ops/sec | 13.8M ops/sec | 13.4M ops/sec |
| C Extension Time/Op | 74.6 ns | 72.5 ns | 74.6 ns |
| Pure Ruby Speed | 2.7M ops/sec | 88K ops/sec | 879 ops/sec |
| Pure Ruby Time/Op | 370 ns | 11.4 μs | 1.14 ms |
| Performance Gain | 4.9x | 156x | 15,221x |

## Analysis

### Performance Trends

1. C Extension Performance:
   - Consistent performance across dataset sizes within each Ruby version
   - Significant improvement from Ruby 3.2.8 to 3.3.7/3.4.2
   - Best performance seen in Ruby 3.3.7/3.4.2 (~26-28M ops/sec)

2. Pure Ruby Performance:
   - Improves significantly with newer Ruby versions
   - Most noticeable in large datasets
   - Ruby 3.4.2 shows best Pure Ruby performance

3. YJIT Impact:
   - Substantial improvement in Pure Ruby performance
   - Reduced performance gap between C Extension and Pure Ruby
   - Most effective in newer Ruby versions

### Scaling Characteristics

1. C Extension:
   - Near-constant performance regardless of dataset size
   - Minimal variance in operation time
   - Excellent memory efficiency

2. Pure Ruby:
   - Performance degrades with dataset size
   - Degradation less severe in newer versions
   - YJIT significantly improves scaling behavior

## Conclusions

1. Version Selection:
   - Ruby 3.3.7 or 3.4.2 recommended for optimal performance
   - YJIT provides substantial benefits, especially for Pure Ruby code
   - C Extension maintains excellent performance across all versions

2. Use Case Recommendations:
   - Small Datasets: Both implementations perform well
   - Medium Datasets: C Extension shows clear advantages
   - Large Datasets: C Extension becomes crucial for performance

3. Future Outlook:
   - Continued improvement in Pure Ruby performance with newer versions
   - C Extension maintains significant advantage for large datasets
   - YJIT improvements making Pure Ruby more competitive

## Running the Benchmarks

To run these benchmarks in your environment:

```bash
# Compile the C extensions
bundle exec rake compile

# Run the benchmarks
./bin/run_benchmarks.sh
```

Results will be saved in the `benchmark_results` directory. 