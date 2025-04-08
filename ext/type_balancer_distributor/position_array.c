#include <stdlib.h>
#include "position_array.h"

position_array *create_position_array(size_t capacity) {
    position_array *array = malloc(sizeof(position_array));
    if (!array) {
        return NULL;
    }

    array->data = malloc(capacity * sizeof(size_t));
    if (!array->data) {
        free(array);
        return NULL;
    }

    array->size = 0;
    array->capacity = capacity;
    return array;
}

void free_position_array(position_array *array) {
    if (array) {
        free(array->data);
        free(array);
    }
}

void add_position(position_array *array, size_t position) {
    if (!array || !array->data || array->size >= array->capacity) {
        return;
    }

    array->data[array->size++] = position;
}

size_t get_position(const position_array *array, size_t index) {
    if (!array || !array->data || index >= array->size) {
        return 0;
    }
    return array->data[index];
} 