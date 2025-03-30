#include <math.h>
#include "spacing_calculator.h"

// Calculate the base spacing between positions
double calculate_base_spacing(long total_count, long target_count) {
    if (total_count <= 1 || target_count <= 1) {
        return 0.0;
    }

    // Calculate base spacing as (total_count - 1) / (target_count - 1)
    return (double)(total_count - 1) / (target_count - 1);
}

// Adjust spacing for edge cases and special conditions
double adjust_spacing_for_edge_cases(double spacing, long total_count, long target_count) {
    // For small collections (total_count <= 2), return 0.0
    if (total_count <= 2) {
        return 0.0;
    }

    // For collections of size 3 with target_count = 2, return 2.0
    if (total_count == 3 && target_count == 2) {
        return 2.0;
    }

    // Ensure spacing doesn't exceed total_count
    if (spacing >= total_count) {
        return total_count - 1.0;
    }

    return spacing;
}

// Calculate the final spacing value considering all factors
double calculate_spacing(long total_count, long target_count) {
    // Fast path for common cases
    if (target_count <= 0 || total_count <= 0) return 0.0;
    if (target_count >= total_count) return 1.0;
    if (target_count == 1) return 0.0;  // Put at start

    // Calculate base spacing
    double spacing = calculate_base_spacing(total_count, target_count);

    // Adjust for edge cases
    spacing = adjust_spacing_for_edge_cases(spacing, total_count, target_count);

    return spacing;
} 
