// Position calculator interface
// Responsible for calculating initial position distributions

#ifndef POSITION_CALCULATOR_H
#define POSITION_CALCULATOR_H

#include <ruby.h>

// Configuration for position calculation
typedef struct {
    long total_count;    // Total number of positions available
    long target_count;   // Number of positions to calculate
} PositionConfig;

// Result of position calculation
typedef struct {
    long* positions;     // Array of calculated positions
    long count;         // Number of positions calculated
    int error_code;     // 0 for success, non-zero for error
} PositionResult;

// Calculate target count based on total count and ratio
// Returns calculated target count, respecting available_items limit
long calculate_target_count(long total_count, long available_items, double target_ratio);

// Calculate initial position distribution
// Returns array of positions and count in PositionResult
// Caller is responsible for freeing positions array
PositionResult calculate_positions(PositionConfig* config);

// Free resources associated with a PositionResult
void free_position_result(PositionResult* result);

#endif // POSITION_CALCULATOR_H 
