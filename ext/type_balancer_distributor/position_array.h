#ifndef POSITION_ARRAY_H
#define POSITION_ARRAY_H

#include <stddef.h>

// Structure to hold an array of positions
typedef struct {
    size_t *data;
    size_t size;
    size_t capacity;
} position_array;

// Create a new position array with the given capacity
position_array *create_position_array(size_t capacity);

// Free resources associated with a position array
void free_position_array(position_array *array);

// Add a position to the array
void add_position(position_array *array, size_t position);

// Get the position at the given index
size_t get_position(const position_array *array, size_t index);

#endif // POSITION_ARRAY_H 