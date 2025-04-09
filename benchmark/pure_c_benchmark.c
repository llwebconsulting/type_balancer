#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "../ext/type_balancer/position_calculator.h"
#include "../ext/type_balancer/position_array.h"

// Benchmark configuration
typedef struct {
    const char* name;
    long total_count;
    double ratio;
    size_t iterations;
} benchmark_case;

benchmark_case TEST_CASES[] = {
    {"Tiny", 100, 0.1, 1000000},
    {"Small", 1000, 0.2, 100000},
    {"Medium", 10000, 0.3, 10000},
    {"Large", 100000, 0.5, 1000}
};

double get_time_in_seconds() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec / 1e9;
}

void run_benchmark(benchmark_case* test) {
    printf("\nRunning pure C benchmark for %s dataset:\n", test->name);
    printf("- Total count: %ld\n", test->total_count);
    printf("- Ratio: %.2f\n", test->ratio);
    printf("- Iterations: %zu\n\n", test->iterations);

    // Generate available items (20% more than needed)
    long target_count = (long)(test->total_count * test->ratio);
    size_t available_count = (size_t)(target_count * 1.2);
    long* available_items = malloc(available_count * sizeof(long));
    for (size_t i = 0; i < available_count; i++) {
        available_items[i] = (long)i;
    }

    // Warmup
    printf("Warming up...\n");
    for (size_t i = 0; i < test->iterations / 10; i++) {
        position_array* result = calculate_positions(
            test->total_count,
            test->ratio,
            available_items,
            available_count
        );
        free_position_array(result);
    }
    printf("Warmup complete.\n\n");

    // Actual benchmark
    double start_time = get_time_in_seconds();
    
    for (size_t i = 0; i < test->iterations; i++) {
        position_array* result = calculate_positions(
            test->total_count,
            test->ratio,
            available_items,
            available_count
        );
        free_position_array(result);
    }

    double end_time = get_time_in_seconds();
    double elapsed = end_time - start_time;
    double ops_per_sec = test->iterations / elapsed;

    printf("Time elapsed: %f seconds\n", elapsed);
    printf("Operations per second: %f\n", ops_per_sec);

    free(available_items);
}

int main() {
    size_t num_cases = sizeof(TEST_CASES) / sizeof(benchmark_case);
    
    for (size_t i = 0; i < num_cases; i++) {
        run_benchmark(&TEST_CASES[i]);
    }

    return 0;
} 