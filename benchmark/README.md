# TypeBalancer Benchmarks

This directory contains benchmarks for measuring TypeBalancer's performance across different Ruby versions and configurations.

## Latest Benchmark Results

Tests run on ARM64 platform (M-series Mac via Docker) with Ruby versions 3.2.8, 3.3.7, and 3.4.2, both with and without YJIT.

### Processing Time by Dataset Size

#### Tiny Dataset (10 items)
- Processing time: ~15 microseconds
- Throughput: ~65-70k operations/second
- Even distribution achieved: 40/30/30 split

#### Small Dataset (100 items)
- Processing time: ~550 microseconds
- Throughput: ~1.8k operations/second
- Even distribution achieved: 34/33/33 split

#### Medium Dataset (1,000 items)
- Processing time: ~50 milliseconds
- Throughput: ~20 operations/second
- Even distribution achieved: 33.4/33.3/33.3 split

#### Large Dataset (10,000 items)
- Processing time: ~4.3-4.7 seconds
- Throughput: ~0.21-0.23 operations/second
- Even distribution achieved: 33.34/33.33/33.33 split

### Performance Analysis

#### Ruby Version Comparison (10,000 items)
| Ruby Version | YJIT | Time (seconds) |
|-------------|------|----------------|
| 3.2.8       | No   | 4.37          |
| 3.2.8       | Yes  | 4.29          |
| 3.3.7       | No   | 4.45          |
| 3.3.7       | Yes  | 4.31          |
| 3.4.2       | No   | 4.71          |
| 3.4.2       | Yes  | 4.71          |

#### Key Findings
1. YJIT Impact:
   - Provides modest improvements (2-3%) on larger datasets
   - Most effective with Ruby 3.2.8
   - Diminishing returns in newer Ruby versions

2. Scaling Characteristics:
   - Performance scales non-linearly with dataset size
   - Sweet spot appears to be around 1,000 items
   - Processing time increases significantly beyond 1,000 items

3. Distribution Quality:
   - Maintains excellent distribution ratios across all dataset sizes
   - Larger datasets achieve near-perfect distribution (33.33%)

## Current Limitations and Future Work

1. Performance Concerns:
   - Large datasets (>10,000 items) process slower than desired
   - Non-linear scaling suggests algorithmic optimization opportunities
   - Current implementation prioritizes distribution quality over speed

2. Optimization Priorities:
   - Improve processing time for large datasets
   - Investigate algorithmic improvements in distribution logic
   - Explore parallel processing options for large collections

3. Recommendations:
   - For production use, process collections of ≤1,000 items at a time
   - Break larger datasets into smaller batches
   - Monitor memory usage with very large collections

## Running Benchmarks

To run the benchmarks:

```bash
# Run all Ruby versions with and without YJIT
./bin/run_benchmarks.sh --platform linux/arm64

# Run specific version with YJIT
./bin/run_benchmarks.sh -v 3.3.8 --yjit --platform linux/arm64

# Run specific version without YJIT
./bin/run_benchmarks.sh -v 3.3.8 --no-yjit --platform linux/arm64
```

Results will be saved in the `benchmark_results` directory. 