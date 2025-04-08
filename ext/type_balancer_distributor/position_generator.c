#include "position_generator.h"
#include "spacing_calculator.h"

position_array *generate_consecutive_positions(long count) {
    position_array *array = create_position_array(count);
    if (!array) {
        return NULL;
    }

    for (long i = 0; i < count && i <= count - 1; i++) {
        add_position(array, (size_t)i);
    }

    return array;
}

position_array *generate_spaced_positions(long total_count, double spacing, long target_count) {
    position_array *array = create_position_array(target_count);
    if (!array) {
        return NULL;
    }

    // Special case: spacing of 0 means only use first position
    if (spacing == 0.0) {
        add_position(array, 0);
        return array;
    }

    long current_pos = 0;
    for (long i = 0; i < target_count && current_pos <= total_count - 1; i++) {
        add_position(array, (size_t)current_pos);
        current_pos += (long)spacing;
    }

    return array;
}

position_array *generate_positions(long total_count, long target_count) {
    // Handle empty or invalid cases
    if (total_count <= 0 || target_count <= 0) {
        return create_position_array(0);
    }

    // Handle single position case
    if (target_count == 1) {
        position_array *array = create_position_array(1);
        if (array) {
            add_position(array, 0);
        }
        return array;
    }

    // If target_count >= total_count, use consecutive positions
    if (target_count >= total_count) {
        return generate_consecutive_positions(total_count);
    }

    // Calculate spacing and generate positions
    double spacing = calculate_spacing(total_count, target_count);
    return generate_spaced_positions(total_count, spacing, target_count);
}

void calculate_spaced_positions(position_array *positions, size_t collection_size, size_t item_count) {
    if (!positions || collection_size == 0 || item_count == 0) {
        return;
    }

    // Calculate spacing between items
    double spacing = calculate_spacing((long)collection_size, (long)item_count);
    
    // Generate positions with calculated spacing
    size_t current_pos = 0;
    for (size_t i = 0; i < item_count && current_pos < collection_size; i++) {
        add_position(positions, current_pos);
        current_pos += (size_t)spacing;
    }
} 