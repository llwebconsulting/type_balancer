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
- Performance compared between YJIT enabled and disabled

## Detailed Results

### Ruby 3.4.2 Performance

| Metric | Small Dataset | Medium Dataset | Large Dataset |
|--------|--------------|----------------|---------------|
| With YJIT Speed | 3.8M ops/sec | 234K ops/sec | 3.0K ops/sec |
| With YJIT Time/Op | 260 ns | 4.3 μs | 331.8 μs |
| Without YJIT Speed | 2.7M ops/sec | 180K ops/sec | 2.2K ops/sec |
| Without YJIT Time/Op | 370 ns | 5.6 μs | 454.5 μs |
| Performance Gain | 1.4x | 1.3x | 1.36x |

### Ruby 3.3.7 Performance

| Metric | Small Dataset | Medium Dataset | Large Dataset |
|--------|--------------|----------------|---------------|
| With YJIT Speed | 3.3M ops/sec | 109K ops/sec | 1.6K ops/sec |
| With YJIT Time/Op | 305.3 ns | 9.2 μs | 636.4 μs |
| Without YJIT Speed | 2.4M ops/sec | 88K ops/sec | 1.2K ops/sec |
| Without YJIT Time/Op | 416.7 ns | 11.4 μs | 833.3 μs |
| Performance Gain | 1.37x | 1.24x | 1.33x |

### Ruby 3.2.8 Performance

| Metric | Small Dataset | Medium Dataset | Large Dataset |
|--------|--------------|----------------|---------------|
| With YJIT Speed | 2.7M ops/sec | 88K ops/sec | 879 ops/sec |
| With YJIT Time/Op | 370 ns | 11.4 μs | 1.14 ms |
| Without YJIT Speed | 2.0M ops/sec | 70K ops/sec | 650 ops/sec |
| Without YJIT Time/Op | 500 ns | 14.3 μs | 1.54 ms |
| Performance Gain | 1.35x | 1.26x | 1.35x |

## Analysis

### Performance Trends

1. YJIT Impact:
   - Consistent performance improvement across all Ruby versions
   - Average 30-40% speedup in most scenarios
   - Most effective in Ruby 3.4.2

2. Version Improvements:
   - Significant performance gains in newer Ruby versions
   - Ruby 3.4.2 shows best overall performance
   - Improved memory efficiency in newer versions

### Scaling Characteristics

1. Dataset Size Impact:
   - Performance scales well with small to medium datasets
   - Large datasets show expected linear performance degradation
   - YJIT benefits remain consistent across dataset sizes

2. Memory Usage:
   - Efficient memory utilization
   - Predictable scaling with dataset size
   - No unexpected memory spikes

## Conclusions

1. Version Selection:
   - Ruby 3.4.2 recommended for optimal performance
   - YJIT provides substantial benefits across all versions
   - Newer versions show better memory efficiency

2. Use Case Recommendations:
   - Small/Medium Datasets: Excellent performance
   - Large Datasets: Consider batch processing for best results
   - YJIT recommended for all use cases

3. Future Outlook:
   - Continued improvement in Ruby performance
   - YJIT optimization getting better with each version
   - Focus on Ruby-native optimizations

## Running the Benchmarks

To run these benchmarks in your environment:

```bash
# Run the benchmarks
./bin/run_benchmarks.sh
```

Results will be saved in the `benchmark_results` directory. 