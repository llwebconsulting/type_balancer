#include "gap_filler.h"
#include "sequential_filler.h"
#include "alternating_filler.h"
#include <ruby.h>

// This file is now just a placeholder for future gap filling functionality.
// All initialization has been moved to init.c.

// Remove this commented-out line entirely
// // VALUE rb_mTypeBalancer; // Keep if needed elsewhere, remove if not.

// Remove the duplicate Init function
/*
void Init_type_balancer(void) {
    // Create the TypeBalancer module
    rb_mTypeBalancer = rb_define_module("TypeBalancer");
    
    // Initialize the sequential filler
    Init_sequential_filler(rb_mTypeBalancer);
    
    // Initialize the alternating filler
    Init_alternating_filler();
} 
*/ 
