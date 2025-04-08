// Position adjuster interface
// Responsible for adjusting positions that exceed bounds or need redistribution

#ifndef POSITION_ADJUSTER_H
#define POSITION_ADJUSTER_H

#include <ruby.h>
#include "position_calculator.h"

// Result codes for position adjustment operations
typedef enum {
    ADJUST_UNCHANGED = 0,   // No changes were needed
    ADJUST_MODIFIED = 1,    // Positions were successfully adjusted
    ADJUST_NO_SPACE = 2,    // No space available for adjustment
    ADJUST_INVALID_INPUT = 3 // Invalid input parameters
} AdjustResult;

// Configuration for position adjustment
typedef struct {
    long* positions;     // Array of positions to adjust
    long count;         // Number of positions
    long total_count;   // Total number of available positions
} AdjustConfig;

// Adjust positions that exceed bounds
// Returns ADJUST_OK on success, error code otherwise
// Modifies positions array in place
AdjustResult adjust_positions(AdjustConfig* config);

// Redistribute positions to maintain even spacing
// Returns ADJUST_OK on success, error code otherwise
// Modifies positions array in place
AdjustResult redistribute_positions(AdjustConfig* config);

#endif // POSITION_ADJUSTER_H 