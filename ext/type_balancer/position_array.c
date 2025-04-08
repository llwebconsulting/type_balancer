#include <stdlib.h>
#include <string.h>
#include "position_array.h"

#ifdef __APPLE__
#include <malloc/malloc.h>
#else
#include <malloc.h>
#endif

// Align memory to cache line boundary
static void* aligned_malloc(size_t size) {
#ifdef _WIN32
    return _aligned_malloc(size, ALIGNMENT_SIZE);
#else
    void* ptr;
    if (posix_memalign(&ptr, ALIGNMENT_SIZE, size) != 0) {
        return NULL;
    }
    return ptr;
#endif
}

static void aligned_free(void* ptr) {
#ifdef _WIN32
    _aligned_free(ptr);
#else
    free(ptr);
#endif
}

position_array *create_position_array(size_t capacity) {
    position_array *array = (position_array *)aligned_malloc(sizeof(position_array));
    if (!array) return NULL;

    // Initialize all fields to zero
    memset(array, 0, sizeof(position_array));
    array->capacity = capacity;
    
    if (capacity <= STATIC_BUFFER_SIZE) {
        array->data = array->static_buffer;
        array->using_static_buffer = 1;
    } else {
        array->data = (size_t *)aligned_malloc(capacity * sizeof(size_t));
        if (!array->data) {
            aligned_free(array);
            return NULL;
        }
        array->using_static_buffer = 0;
    }

    return array;
}

void free_position_array(position_array *array) {
    if (array) {
        if (!array->using_static_buffer) {
            aligned_free(array->data);
        }
        aligned_free(array);
    }
}

int add_position(position_array *array, size_t position) {
    if (!array || array->size >= array->capacity) {
        return 0;
    }
    
    array->data[array->size++] = position;
    return 1;
}

size_t get_position(const position_array *array, size_t index) {
    if (!array || index >= array->size) {
        return 0;
    }
    return array->data[index];
}

const size_t *get_data_ptr(const position_array *array) {
    return array ? array->data : NULL;
}

size_t get_array_size(const position_array *array) {
    return array ? array->size : 0;
} 