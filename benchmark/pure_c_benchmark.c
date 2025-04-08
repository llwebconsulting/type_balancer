#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

#define PASSES_PER_CALCULATION 10000
#define WARMUP_ITERATIONS 100
#define BENCHMARK_ITERATIONS 1000

typedef struct {
    long size;
    long* items;
} ItemBatch;

long calculate_target_count(long total_count, double ratio) {
    if (total_count <= 0 || ratio <= 0.0 || ratio > 1.0) {
        return -1;
    }
    return (long)(total_count * ratio);
}

double get_time_in_seconds() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec / 1e9;
}

long* calculate_positions_with_load(ItemBatch* batch, long target_count, double ratio) {
    if (!batch || target_count <= 0 || ratio <= 0.0 || ratio > 1.0) {
        return NULL;
    }

    target_count = target_count < batch->size ? target_count : batch->size;
    long* positions = (long*)malloc(target_count * sizeof(long));
    if (!positions) {
        return NULL;
    }

    // Temporary buffer for complex calculations
    double* temp_buffer = (double*)malloc(target_count * sizeof(double));
    if (!temp_buffer) {
        free(positions);
        return NULL;
    }

    // Multiple passes with complex calculations
    for (int pass = 0; pass < PASSES_PER_CALCULATION; pass++) {
        double phase = (double)pass / PASSES_PER_CALCULATION * M_PI;
        
        // Initialize temp buffer with complex calculations
        for (long i = 0; i < target_count; i++) {
            double x = (double)i / target_count;
            temp_buffer[i] = sin(x * M_PI + phase) * cos(x * M_PI * 2) * exp(-x);
        }

        // Use temp buffer to influence position calculations
        for (long i = 0; i < target_count; i++) {
            double spacing = (double)batch->size / target_count;
            double raw_pos = i * spacing + temp_buffer[i] * spacing * 0.1;
            
            // Add more complex math operations
            double adjusted_pos = raw_pos;
            for (int j = 0; j < 10; j++) {
                adjusted_pos = fmod(adjusted_pos + sin(adjusted_pos), (double)batch->size);
            }
            
            positions[i] = (long)adjusted_pos;
        }
    }

    free(temp_buffer);
    return positions;
}

void run_benchmark(const char* dataset_name, long total_count, long available_items, double ratio) {
    printf("\nTesting %s dataset with ratio %.1f:\n", dataset_name, ratio);
    printf("- Total count: %ld\n", total_count);
    printf("- Available items: %ld\n\n", available_items);

    // Create test data
    ItemBatch batch = {
        .size = available_items,
        .items = (long*)malloc(available_items * sizeof(long))
    };
    for (long i = 0; i < available_items; i++) {
        batch.items[i] = i;
    }

    long target_count = calculate_target_count(total_count, ratio);
    if (target_count <= 0) {
        printf("Invalid input parameters\n");
        free(batch.items);
        return;
    }

    // Warmup phase
    printf("Warming up for %d iterations...\n", WARMUP_ITERATIONS);
    for (int i = 0; i < WARMUP_ITERATIONS; i++) {
        long* positions = calculate_positions_with_load(&batch, target_count, ratio);
        if (positions) free(positions);
    }
    printf("Warmup complete.\n\n");

    // Benchmark phase
    printf("Running benchmark for %d iterations...\n\n", BENCHMARK_ITERATIONS);
    double start_time = get_time_in_seconds();
    
    for (int i = 0; i < BENCHMARK_ITERATIONS; i++) {
        long* positions = calculate_positions_with_load(&batch, target_count, ratio);
        if (positions) free(positions);
    }
    
    double end_time = get_time_in_seconds();
    double elapsed = end_time - start_time;
    double ops_per_sec = elapsed > 0 ? BENCHMARK_ITERATIONS / elapsed : 0;

    printf("Results:\n");
    printf("Time elapsed: %.6f seconds\n", elapsed);
    printf("Operations per second: %.2f\n", ops_per_sec);

    free(batch.items);
}

int main() {
    printf("Pure C Benchmark\n");
    printf("================\n");

    // Test cases
    struct {
        const char* name;
        long total_count;
        long available_items;
    } test_cases[] = {
        {"Tiny (Blog posts)", 100, 20},
        {"Small (Product catalog)", 1000, 200},
        {"Medium (E-commerce inventory)", 10000, 2000},
        {"Large (User database)", 100000, 20000},
        {"Very Large (Analytics)", 1000000, 200000}
    };

    double ratios[] = {0.1, 0.2, 0.3, 0.5};

    for (size_t i = 0; i < sizeof(test_cases) / sizeof(test_cases[0]); i++) {
        for (size_t j = 0; j < sizeof(ratios) / sizeof(ratios[0]); j++) {
            run_benchmark(
                test_cases[i].name,
                test_cases[i].total_count,
                test_cases[i].available_items,
                ratios[j]
            );
        }
    }

    return 0;
} 