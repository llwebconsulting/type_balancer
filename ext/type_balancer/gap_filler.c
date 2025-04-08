#include "gap_filler.h"
#include "sequential_filler.h"
#include "alternating_filler.h"
#include <ruby.h>

// Most of this file can be removed since we've now separated the implementations
// into separate files. We'll keep just the initialization function.

VALUE rb_mTypeBalancer;

// Initialize the type_balancer extension
void Init_type_balancer(void) {
    // Create the TypeBalancer module
    rb_mTypeBalancer = rb_define_module("TypeBalancer");
    
    // Initialize the sequential filler
    Init_sequential_filler(rb_mTypeBalancer);
    
    // Initialize the alternating filler
    Init_alternating_filler();
} 
