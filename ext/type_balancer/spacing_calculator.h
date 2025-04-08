#ifndef SPACING_CALCULATOR_H
#define SPACING_CALCULATOR_H

#include <ruby.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Calculate the base spacing between positions
double calculate_base_spacing(long total_count, long target_count);

// Adjust spacing for edge cases and special conditions
double adjust_spacing_for_edge_cases(double spacing, long total_count, long target_count);

// Calculate the final spacing value considering all factors
double calculate_spacing(long total_count, long target_count);

// Calculate the initial offset for centering items
size_t calculate_initial_offset(size_t collection_size, size_t item_count, size_t spacing);

// Calculate target count based on total count and ratio
// Returns calculated target count, respecting available_items limit
long calculate_target_count(long total_count, long available_items, double target_ratio);

// Calculate spacing for multiple inputs at once using SIMD
void calculate_spacing_batch(const long* total_counts, const long* target_counts, 
                           double* results, size_t count);

// Calculate spacing for multiple inputs with custom batch size
void calculate_spacing_batch_preallocated(const long* total_counts, const long* target_counts,
                                        double* results, size_t count, size_t batch_size);

#ifdef __cplusplus
}
#endif

#endif // SPACING_CALCULATOR_H 