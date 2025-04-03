#ifndef USERS_ANON_GEMS_TYPE_BALANCER_EXT_TYPE_BALANCER_ALTERNATING_FILLER_H
#define USERS_ANON_GEMS_TYPE_BALANCER_EXT_TYPE_BALANCER_ALTERNATING_FILLER_H

#include "item_queue.h"
#include <ruby.h>

#ifdef __cplusplus
extern "C" {
#endif

// Structure to hold alternating filler context
typedef struct {
    item_queue *primary_items;
    item_queue *secondary_items;
    VALUE result_ptr;
    size_t result_size;
} alternating_filler_context;

// Initialize the alternating filler module
void Init_alternating_filler(void);

// Create a new alternating filler context
alternating_filler_context *create_alternating_filler_context(
    item_queue *first_priority_items,  // Items to be used first when filling gaps
    item_queue *second_priority_items  // Items to be used when first priority items are exhausted
);

// Free resources associated with an alternating filler context
void free_alternating_filler_context(alternating_filler_context *filler);

// Fill gaps in a collection using alternating items
void fill_gaps_alternating_context(alternating_filler_context *filler, const long *positions, size_t position_count);

#ifdef __cplusplus
}
#endif

#endif /* USERS_ANON_GEMS_TYPE_BALANCER_EXT_TYPE_BALANCER_ALTERNATING_FILLER_H */
