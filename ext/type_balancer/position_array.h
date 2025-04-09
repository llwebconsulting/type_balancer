#ifndef POSITION_ARRAY_H
#define POSITION_ARRAY_H

#include <ruby.h>

// Structure to hold an array of positions
typedef struct {
    double *data;          // Pointer to position data
    size_t size;          // Current number of positions
    size_t capacity;      // Total capacity
    double static_buffer[32]; // Static buffer for small arrays
    int using_static_buffer;  // Flag indicating if static buffer is in use
} position_array;

// Function declarations
position_array* create_position_array(size_t initial_capacity);
void free_position_array(position_array* array);
int add_position(position_array* array, double position);
double get_position(const position_array* array, size_t index);
double* get_data_ptr(const position_array* array);
size_t get_size(const position_array* array);

// Ruby TypedData structure
extern const rb_data_type_t position_array_type;

#endif // POSITION_ARRAY_H 