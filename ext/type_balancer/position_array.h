#ifndef POSITION_ARRAY_H
#define POSITION_ARRAY_H

#include <stddef.h>
#include <stdint.h>

// Optimize for L1 cache line size (64 bytes on most CPUs)
#define STATIC_BUFFER_SIZE 16
#define ALIGNMENT_SIZE 64

// Structure to hold an array of positions
typedef struct {
    size_t *data;              // Main data pointer (aligned for SIMD)
    size_t size;              // Current number of elements
    size_t capacity;          // Total capacity
    size_t static_buffer[STATIC_BUFFER_SIZE] __attribute__((aligned(ALIGNMENT_SIZE))); // Aligned static buffer
    uint8_t using_static_buffer; // Use uint8_t instead of int for better packing
    uint8_t padding[7];       // Ensure proper alignment
} __attribute__((aligned(ALIGNMENT_SIZE))) position_array;

// Create a new position array with the given capacity
// Returns NULL if allocation fails
position_array *create_position_array(size_t capacity);

// Free resources associated with a position array
void free_position_array(position_array *array);

// Add a position to the array
// Returns 1 if successful, 0 if array is full or NULL
int add_position(position_array *array, size_t position);

// Get the position at the given index
// Returns 0 if index is out of bounds or array is NULL
size_t get_position(const position_array *array, size_t index);

// Get direct access to the underlying data array
// Use with caution - no bounds checking
const size_t *get_data_ptr(const position_array *array);

// Get the current size of the array
size_t get_array_size(const position_array *array);

#endif // POSITION_ARRAY_H 