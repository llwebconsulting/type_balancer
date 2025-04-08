// Position calculator interface
// Responsible for calculating initial position distributions

#ifndef USERS_ANON_GEMS_TYPE_BALANCER_EXT_TYPE_BALANCER_POSITION_CALCULATOR_H
#define USERS_ANON_GEMS_TYPE_BALANCER_EXT_TYPE_BALANCER_POSITION_CALCULATOR_H

#include <stddef.h>

// Error codes for position calculation
#define POSITION_SUCCESS 0
#define POSITION_INVALID_INPUT 1
#define POSITION_MEMORY_ERROR 2

// Configuration for position calculation
typedef struct {
    long total_count;    // Total number of positions available
    long target_count;   // Number of positions to calculate
} PositionConfig;

// Result structure for position calculation
typedef struct {
    double* positions;   // Array of calculated positions
    size_t count;       // Number of positions in the array
    int error_code;     // Error code (0 for success)
} PositionResult;

// Calculate target count based on total count and ratio
// Returns calculated target count, respecting available_items limit
long calculate_target_count(long total_count, long available_items, double target_ratio);

// Calculate positions based on configuration
PositionResult calculate_positions(const PositionConfig* config);

// Free resources associated with a position result
void free_position_result(PositionResult* result);

#endif /* USERS_ANON_GEMS_TYPE_BALANCER_EXT_TYPE_BALANCER_POSITION_CALCULATOR_H */ 
