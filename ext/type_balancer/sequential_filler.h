#ifndef SEQUENTIAL_FILLER_H
#define SEQUENTIAL_FILLER_H

#include <ruby.h>
#include "item_queue.h"

// Declare the Ruby module and class
extern VALUE rb_mTypeBalancer;
extern VALUE rb_cSequentialFiller;

#ifdef __cplusplus
extern "C" {
#endif

// Structure to hold sequential filler context
typedef struct {
    item_queue **queues;      // Array of item queues
    size_t queue_count;       // Number of queues
    size_t current_queue;     // Current queue index
    VALUE source_arrays;      // Keep reference to prevent GC
    VALUE *result_ptr;        // Pointer to result array
    size_t result_size;       // Size of result array
} sequential_filler_context;

// Type declaration for sequential filler
extern const rb_data_type_t sequential_filler_type;

// Create a new sequential filler context
sequential_filler_context *create_sequential_filler_context(VALUE items_arrays);

// Free resources associated with a sequential filler context
void free_sequential_filler_context(sequential_filler_context *filler);

// Fill gaps in a collection using sequential filler
VALUE fill_gaps_sequential_context(VALUE self, VALUE collection, VALUE positions, sequential_filler_context* filler);

// Find the next item in the sequential filler
VALUE find_next_item(VALUE self);

// Ruby method declarations
VALUE rb_sequential_filler_fill(int argc, VALUE* argv, VALUE klass);
VALUE rb_sequential_filler_initialize(int argc, VALUE* argv, VALUE self);
VALUE rb_sequential_filler_fill_gaps(int argc, VALUE* argv, VALUE self);
VALUE sequential_filler_alloc(VALUE klass);

// Initialize the sequential filler module
void Init_sequential_filler(VALUE mTypeBalancer);

#ifdef __cplusplus
}
#endif

#endif // SEQUENTIAL_FILLER_H 
