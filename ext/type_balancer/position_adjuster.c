#include <stdlib.h>
#include "position_adjuster.h"

// Adjust positions that exceed bounds
AdjustResult adjust_positions(AdjustConfig* config) {
    if (!config || !config->positions || config->count <= 0 || config->total_count <= 0) {
        return ADJUST_INVALID_INPUT;
    }

    int adjusted = 0;
    for (long i = 0; i < config->count; i++) {
        // Skip if position is already within bounds
        if (config->positions[i] < config->total_count) {
            continue;
        }

        // Find the nearest available position
        long new_pos = config->total_count - 1;
        while (new_pos >= 0) {
            int position_taken = 0;
            
            // Check if position is already taken
            for (long j = 0; j < i; j++) {
                if (config->positions[j] == new_pos) {
                    position_taken = 1;
                    break;
                }
            }

            if (!position_taken) {
                config->positions[i] = new_pos;
                adjusted = 1;
                break;
            }
            new_pos--;
        }

        // If no position found, return error
        if (new_pos < 0) {
            return ADJUST_NO_SPACE;
        }
    }

    return adjusted ? ADJUST_MODIFIED : ADJUST_UNCHANGED;
}

// Redistribute positions to maintain even spacing
AdjustResult redistribute_positions(AdjustConfig* config) {
    if (!config || !config->positions || config->count <= 0 || config->total_count <= 0) {
        return ADJUST_INVALID_INPUT;
    }

    // No need to redistribute if we have 0 or 1 position
    if (config->count <= 1) {
        return ADJUST_UNCHANGED;
    }

    // Calculate ideal spacing
    double spacing = (double)(config->total_count - 1) / (double)(config->count - 1);
    int modified = 0;

    // Redistribute positions
    for (long i = 0; i < config->count; i++) {
        double ideal_pos = i * spacing;
        long new_pos = (long)(ideal_pos + 0.5); // Round to nearest integer

        if (config->positions[i] != new_pos) {
            config->positions[i] = new_pos;
            modified = 1;
        }
    }

    return modified ? ADJUST_MODIFIED : ADJUST_UNCHANGED;
} 