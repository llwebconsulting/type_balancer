#include <ruby.h>
#include "position_calculator.h"
#include "position_array.h"
#include "sequential_filler.h"
#include "alternating_filler.h"

// Declare external functions
extern VALUE rb_calculate_positions(VALUE self, VALUE target_count_val, VALUE available_items_val);
extern VALUE rb_calculate_positions_native(VALUE self, VALUE target_count_val, VALUE available_items_val);

// Define rb_mTypeBalancer globally (or static if only needed within this TU)
VALUE rb_mTypeBalancer; 

// Initialize the type_balancer extension
void Init_native(void) {
    // Assign to the global variable instead of declaring locally
    rb_mTypeBalancer = rb_define_module("TypeBalancer");
    VALUE mNative = rb_define_module_under(rb_mTypeBalancer, "Native");
    
    // Initialize the sequential filler - Pass the module VALUE explicitly
    Init_sequential_filler(rb_mTypeBalancer); 
    
    // Initialize the alternating filler
    Init_alternating_filler();
    
    // Initialize the position calculator
    rb_define_singleton_method(mNative, "calculate_positions", rb_calculate_positions, 2);
    rb_define_singleton_method(mNative, "calculate_positions_native", rb_calculate_positions_native, 2);
} 