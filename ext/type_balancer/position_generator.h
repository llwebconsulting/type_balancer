#ifndef POSITION_GENERATOR_H
#define POSITION_GENERATOR_H

#include "position_array.h"
#include "spacing_calculator.h"

// Generate consecutive positions (0, 1, 2, ...)
position_array *generate_consecutive_positions(long count);

// Generate positions with the given spacing
position_array *generate_spaced_positions(long total_count, double spacing, long target_count);

// Generate positions for a specific case (handles all scenarios)
position_array *generate_positions(long total_count, long target_count);

// Calculate positions for items with equal spacing
void calculate_spaced_positions(position_array *positions, size_t collection_size, size_t item_count);

#endif // POSITION_GENERATOR_H 