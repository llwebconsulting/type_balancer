#include <stdlib.h>
#include <math.h>
#include "position_calculator.h"
#include "position_generator.h"

// Calculate target count based on total count and ratio
long calculate_target_count(long total_count, long available_items, double target_ratio) {
    // Handle invalid inputs
    if (total_count <= 0 || available_items <= 0 || target_ratio <= 0.0 || target_ratio > 1.0) {
        return 0;
    }
    
    // Calculate target count based on ratio
    long target = (long)round(total_count * target_ratio);
    
    // Ensure at least one position if ratio is positive
    if (target == 0 && target_ratio > 0.0) {
        target = 1;
    }
    
    // Limit by available items and total count
    if (target > available_items) {
        target = available_items;
    }
    if (target > total_count) {
        target = total_count;
    }
    
    return target;
}

// Calculate initial position distribution
PositionResult calculate_positions(PositionConfig* config) {
    PositionResult result = {NULL, 0, 0};
    
    // Handle edge cases and invalid input
    if (!config || config->total_count <= 0) {
        result.error_code = 1;
        return result;
    }
    
    // Handle zero target count as a valid case
    if (config->target_count == 0) {
        result.positions = (long*)malloc(sizeof(long));
        if (!result.positions) {
            result.error_code = 2;
            return result;
        }
        result.count = 0;
        result.error_code = 0;
        return result;
    }
    
    // Check if target count is valid
    if (config->target_count < 0 || config->target_count > config->total_count) {
        result.error_code = 1;
        return result;
    }
    
    // Allocate memory for positions
    result.positions = (long*)malloc(config->target_count * sizeof(long));
    if (!result.positions) {
        result.error_code = 2;
        return result;
    }
    
    // Handle single item case
    if (config->target_count == 1) {
        result.positions[0] = 0;
        result.count = 1;
        result.error_code = 0;
        return result;
    }
    
    // Handle case where we need all positions
    if (config->target_count == config->total_count) {
        for (long i = 0; i < config->target_count; i++) {
            result.positions[i] = i;
        }
        result.count = config->target_count;
        result.error_code = 0;
        return result;
    }
    
    // Calculate spacing between positions for even distribution
    double spacing = (double)(config->total_count - 1) / (config->target_count - 1);
    
    // Calculate positions with even spacing
    for (long i = 0; i < config->target_count; i++) {
        double exact_pos = i * spacing;
        long rounded_pos = (long)round(exact_pos);
        
        // Ensure position is within bounds
        if (rounded_pos >= config->total_count) {
            rounded_pos = config->total_count - 1;
        }
        
        result.positions[i] = rounded_pos;
    }
    
    // Ensure last position is at the end if we're not using all positions
    if (config->target_count > 1 && config->target_count < config->total_count) {
        result.positions[config->target_count - 1] = config->total_count - 1;
    }
    
    result.count = config->target_count;
    result.error_code = 0;
    return result;
}

// Free resources associated with a PositionResult
void free_position_result(PositionResult* result) {
    if (result && result->positions) {
        free(result->positions);
        result->positions = NULL;
        result->count = 0;
    }
} 