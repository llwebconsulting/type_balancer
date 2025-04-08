// Main distributor interface
// Coordinates position calculation and adjustment for the Ruby extension

#ifndef DISTRIBUTOR_H
#define DISTRIBUTOR_H

#include <ruby.h>
#include "position_calculator.h"

// Initialize the extension
void Init_distributor(void);

// Ruby method: calculate_target_positions(total_count, available_items, target_ratio)
// Returns an array of calculated positions
static VALUE rb_calculate_target_positions(VALUE self, VALUE total, VALUE available, VALUE ratio);

#endif /* DISTRIBUTOR_H */ 
