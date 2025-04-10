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

Each benchmark test evaluates performance across different collection sizes, from small content feeds to large-scale collections:

1. Tiny Dataset (Content Widget):
   - Total Items: 10
   - Distribution: Video (40%), Image (30%), Article (30%)
   - Processing Time: ~12 microseconds

2. Small Dataset (Content Feed):
   - Total Items: 100
   - Distribution: Video (34%), Image (33%), Article (33%)
   - Processing Time: ~464 microseconds

3. Medium Dataset (Category Page):
   - Total Items: 1,000
   - Distribution: Video (33.4%), Image (33.3%), Article (33.3%)
   - Processing Time: ~19 milliseconds

4. Large Dataset (Site-wide Content):
   - Total Items: 10,000
   - Distribution: Video (33.34%), Image (33.33%), Article (33.33%)
   - Processing Time: ~191 milliseconds

### Real-world Application

TypeBalancer is designed for practical use in content management and display systems:
- Process 10,000 items in under 200ms
- Maintain perfect distribution ratios
- Suitable for real-time web applications
- Efficient enough for on-the-fly content organization

### Measurement Approach

- Each test scenario is run multiple times to ensure statistical significance
- Both wall-clock time and CPU time are measured
- Results include operations per second and time per operation
- Benchmark-ips gem used for iterations per second calculations
- Performance measured across different Ruby versions and configurations

## Detailed Results

### Ruby 3.4.2 Performance (with PRISM)

| Metric | Tiny Dataset | Small Dataset | Medium Dataset | Large Dataset |
|--------|--------------|---------------|----------------|---------------|
| Speed (no YJIT) | 73.3K ops/sec | 2.0K ops/sec | 46.9 ops/sec | 4.8 ops/sec |
| Speed (YJIT) | 102.0K ops/sec | 2.1K ops/sec | 46.2 ops/sec | 4.8 ops/sec |
| Time/Op (no YJIT) | 13.63 μs | 494.84 μs | 21.34 ms | 207.62 ms |
| Time/Op (YJIT) | 9.80 μs | 478.05 μs | 21.64 ms | 208.85 ms |
| YJIT Impact | +39.1% | +3.5% | -1.4% | -0.6% |
| Distribution Quality | Perfect | Excellent | Excellent | Excellent |

### Ruby 3.3.7 Performance

| Metric | Tiny Dataset | Small Dataset | Medium Dataset | Large Dataset |
|--------|--------------|---------------|----------------|---------------|
| Speed (no YJIT) | 74.8K ops/sec | 2.1K ops/sec | 49.2 ops/sec | 5.1 ops/sec |
| Speed (YJIT) | 108.1K ops/sec | 2.3K ops/sec | 48.8 ops/sec | 5.2 ops/sec |
| Time/Op (no YJIT) | 13.37 μs | 477.95 μs | 20.34 ms | 196.05 ms |
| Time/Op (YJIT) | 9.25 μs | 437.36 μs | 20.49 ms | 193.08 ms |
| YJIT Impact | +44.5% | +9.3% | -0.7% | +1.5% |
| Distribution Quality | Perfect | Excellent | Excellent | Excellent |

### Ruby 3.2.8 Performance

| Metric | Tiny Dataset | Small Dataset | Medium Dataset | Large Dataset |
|--------|--------------|---------------|----------------|---------------|
| Speed (no YJIT) | 72.2K ops/sec | 2.2K ops/sec | 46.3 ops/sec | 4.7 ops/sec |
| Speed (YJIT) | 108.8K ops/sec | 2.2K ops/sec | 47.3 ops/sec | 5.2 ops/sec |
| Time/Op (no YJIT) | 13.86 μs | 451.35 μs | 21.59 ms | 215.04 ms |
| Time/Op (YJIT) | 9.19 μs | 449.99 μs | 21.15 ms | 193.67 ms |
| YJIT Impact | +50.8% | +0.3% | +2.1% | +11.0% |
| Distribution Quality | Perfect | Excellent | Excellent | Excellent |

## Analysis

### Performance Characteristics

1. Speed and Efficiency:
   - Processes 10K items in ~200ms across all Ruby versions
   - Microsecond-level processing for small collections (9-14μs)
   - Millisecond-level processing for large collections (193-209ms)
   - YJIT provides significant speedup for tiny datasets (39-51% faster)
   - Suitable for real-time web applications

2. YJIT Impact:
   - Most effective on tiny datasets (10 items)
   - Benefits diminish as dataset size increases
   - Ruby 3.2.8 shows most consistent YJIT improvements
   - Some versions show slight regressions on larger datasets

3. Distribution Quality:
   - Perfect distribution in small datasets
   - Highly accurate distribution in larger datasets
   - Consistent quality across all Ruby versions and YJIT settings

### Scaling Characteristics

1. Dataset Size Impact:
   - Predictable performance scaling with size
   - Sub-second processing even for large datasets
   - Reliable performance characteristics

2. Memory Usage:
   - Efficient memory utilization
   - Predictable memory patterns
   - Stable across different workloads

3. Distribution Quality:
   - Maintains high accuracy at all scales
   - Improves with larger datasets
   - Consistent across implementations

## Use Cases

1. Content Management Systems:
   - Homepage feeds (100s of items): < 1ms processing
   - Category pages (1000s of items): ~20ms processing
   - Site-wide content (10,000s of items): ~200ms processing

2. Real-time Applications:
   - Widget content balancing: microsecond response
   - Feed generation: sub-millisecond processing
   - Content reorganization: real-time capable

3. Batch Processing:
   - Large collection processing: efficient and reliable
   - Consistent performance characteristics
   - Predictable resource usage

## Conclusions

1. Version Selection:
   - Ruby 3.2.8 shows optimal performance
   - All versions maintain high distribution quality
   - Version choice can be based on other requirements

2. Production Readiness:
   - Suitable for production workloads
   - Handles large datasets efficiently
   - Real-time processing capable

3. Future Outlook:
   - Continued optimization for larger datasets
   - Focus on maintaining distribution quality
   - Performance improvements in newer Ruby versions

## Running the Benchmarks

To run these benchmarks in your environment:

```bash
# Run all benchmarks
./bin/run_benchmarks.sh

# Run for specific platform
./bin/run_benchmarks.sh --platform linux/arm64

# Run for specific Ruby version
./bin/run_benchmarks.sh --version 3.2.8
```

Results will be saved in the `benchmark_results` directory. 