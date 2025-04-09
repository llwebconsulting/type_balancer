#include <stdlib.h>
#include <string.h>
#include <ruby.h>
#include "position_array.h"

#define STATIC_BUFFER_SIZE 32

// --- TypedData functions ---
static void position_array_mark(void* ptr) {
    // No Ruby objects to mark
    (void)ptr;
}

// Internal free function (used by Ruby GC)
static void position_array_free(void* ptr) {
    position_array* array = (position_array*)ptr;
    if (array) {
        if (!array->using_static_buffer && array->data) {
            free(array->data);
        }
        free(array);
    }
}

static size_t position_array_size(const void* ptr) {
    const position_array* array = (const position_array*)ptr;
    if (!array) return 0;
    return sizeof(position_array) + (array->using_static_buffer ? 0 : array->capacity * sizeof(double));
}

// Ruby TypedData definition
const rb_data_type_t position_array_type = {
    .wrap_struct_name = "PositionArray",
    .function = {
        .dmark = position_array_mark,
        .dfree = position_array_free,
        .dsize = position_array_size,
    },
    .data = NULL,
    .flags = RUBY_TYPED_FREE_IMMEDIATELY,
};


// --- Public C API Functions ---

position_array* create_position_array(size_t initial_capacity) {
    position_array* array = (position_array*)malloc(sizeof(position_array));
    if (!array) return NULL;

    array->size = 0;
    array->data = NULL;
    array->using_static_buffer = 0;

    // Use static buffer for small arrays
    if (initial_capacity <= STATIC_BUFFER_SIZE) {
        array->data = array->static_buffer;
        array->capacity = STATIC_BUFFER_SIZE;
        array->using_static_buffer = 1;
    } else {
        array->data = (double*)malloc(sizeof(double) * initial_capacity);
        if (!array->data) {
            free(array);
            return NULL;
        }
        array->capacity = initial_capacity;
    }

    return array;
}

// Public free function (matches header declaration)
void free_position_array(position_array* array) {
    if (array) {
        if (!array->using_static_buffer && array->data) {
            free(array->data);
        }
        free(array);
    }
}

// Get current number of elements (matches header declaration)
size_t get_size(const position_array* array) {
    return array ? array->size : 0;
}

// Add an element, resizing if necessary
int add_position(position_array* array, double position) {
    if (!array) return -1;

    // Check if we need to grow the array
    if (array->size >= array->capacity) {
        size_t new_capacity = array->capacity == 0 ? STATIC_BUFFER_SIZE : array->capacity * 2;
        double* new_data = (double*)malloc(sizeof(double) * new_capacity);
        if (!new_data) return -1;

        // Copy existing data
        if (array->data) {
            memcpy(new_data, array->data, array->size * sizeof(double));
        }

        // Free old data if it wasn't using static buffer
        if (!array->using_static_buffer && array->data) {
            free(array->data);
        }

        array->data = new_data;
        array->capacity = new_capacity;
        array->using_static_buffer = 0;
    }

    array->data[array->size++] = position;
    return 0;
}

// Get element at a specific index
double get_position(const position_array* array, size_t index) {
    if (!array || index >= array->size) return 0.0;
    return array->data[index];
}

// Get a direct pointer to the data (use with caution)
double* get_data_ptr(const position_array* array) {
    return array ? array->data : NULL;
}