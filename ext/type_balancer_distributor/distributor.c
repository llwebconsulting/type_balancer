#include <ruby.h>
#include "distributor.h"
#include "position_calculator.h"

// Ruby method: calculate_target_positions(total_count, available_items, target_ratio)
static VALUE rb_calculate_target_positions(VALUE self, VALUE rb_total_count, VALUE rb_available_items, VALUE rb_target_ratio) {
    // Get TypeBalancer::Error class
    VALUE mTypeBalancer = rb_const_get(rb_cObject, rb_intern("TypeBalancer"));
    VALUE eTypeBalancerError = rb_const_get(mTypeBalancer, rb_intern("Error"));

    // Convert Ruby values to C types
    long total_count = NUM2LONG(rb_total_count);
    long available_items = NUM2LONG(rb_available_items);
    double target_ratio = NUM2DBL(rb_target_ratio);

    // Validate input
    if (total_count < 0) {
        rb_raise(eTypeBalancerError, "Invalid total count: must be non-negative");
    }
    if (available_items < 0) {
        rb_raise(eTypeBalancerError, "Invalid available items: must be non-negative");
    }
    if (target_ratio < 0.0 || target_ratio > 1.0) {
        rb_raise(eTypeBalancerError, "Invalid ratio: must be between 0 and 1");
    }

    // Handle edge cases
    if (total_count == 0 || available_items == 0) {
        return rb_ary_new();
    }

    // Calculate target count
    long target_count = calculate_target_count(total_count, available_items, target_ratio);
    if (target_count == 0) {
        return rb_ary_new();
    }

    // Configure position calculation
    PositionConfig pos_config = {
        .total_count = total_count,
        .target_count = target_count
    };

    // Calculate positions
    PositionResult pos_result = calculate_positions(&pos_config);
    
    // Create Ruby array for result
    VALUE result = rb_ary_new_capa(pos_result.count);
    
    // Handle errors and convert result to Ruby array
    if (pos_result.error_code != 0) {
        if (pos_result.positions) {
            free(pos_result.positions);
        }
        rb_raise(eTypeBalancerError, "Failed to calculate positions");
    }

    // Convert positions to Ruby array
    for (long i = 0; i < pos_result.count; i++) {
        rb_ary_push(result, LONG2NUM(pos_result.positions[i]));
    }

    // Clean up
    if (pos_result.positions) {
        free(pos_result.positions);
    }

    return result;
}

// Initialize the extension
void Init_distributor(void) {
    VALUE mTypeBalancer = rb_define_module("TypeBalancer");
    VALUE cDistributor = rb_define_class_under(mTypeBalancer, "Distributor", rb_cObject);
    
    rb_define_singleton_method(cDistributor, "calculate_target_positions", rb_calculate_target_positions, 3);
} 
