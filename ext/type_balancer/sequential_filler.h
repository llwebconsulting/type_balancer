#ifndef USERS_ANON_GEMS_TYPE_BALANCER_EXT_TYPE_BALANCER_SEQUENTIAL_FILLER_H
#define USERS_ANON_GEMS_TYPE_BALANCER_EXT_TYPE_BALANCER_SEQUENTIAL_FILLER_H

#include <ruby.h>
#include <ruby/intern.h>

// Context for sequential filling operations
typedef struct {
    VALUE result;           // Result array
    VALUE collection;       // Input collection
    long current_position;  // Current position being processed
    long total_positions;   // Total number of positions
} sequential_filler_context;

// Initialize the sequential filler module
void Init_sequential_filler(VALUE mTypeBalancer);

// Fill gaps in the sequence using the provided context
void fill_gaps_sequential_context(sequential_filler_context *filler, const long *positions, size_t position_count);

#endif /* USERS_ANON_GEMS_TYPE_BALANCER_EXT_TYPE_BALANCER_SEQUENTIAL_FILLER_H */ 
