#include <ruby.h>
#include <ruby/intern.h>
#include "position_array.h"
#include "position_calculator.h"

// Global variable to hold the PositionArray class
static VALUE cPositionArray;

// Forward declare the position_array_type
extern const rb_data_type_t position_array_type;

// Convert Ruby array to C double array
static double* rb_ary_to_doubles(VALUE ary, size_t* size) {
    Check_Type(ary, T_ARRAY);
    *size = RARRAY_LEN(ary);
    double* result = ALLOC_N(double, *size);
    
    for (size_t i = 0; i < *size; i++) {
        result[i] = NUM2DBL(rb_ary_entry(ary, i));
    }
    
    return result;
}

// Convert C double array to Ruby array
static VALUE doubles_to_rb_ary(const double* arr, size_t size) {
    VALUE result = rb_ary_new_capa(size);
    for (size_t i = 0; i < size; i++) {
        rb_ary_push(result, DBL2NUM(arr[i]));
    }
    return result;
}

// Calculate positions using native C types
PositionResult calculate_positions_native(const PositionConfig *config) {
    PositionResult result;
    result.error_code = 0;
    
    if (config->target_count <= 0 || config->total_count <= 0) {
        result.error_code = 1; // Invalid input
        result.count = 0;
        result.positions = NULL;
        return result;
    }
    
    if (config->target_count > config->total_count) {
        result.error_code = 2; // Target count exceeds total count
        result.count = 0;
        result.positions = NULL;
        return result;
    }
    
    // Allocate memory for positions
    result.positions = ALLOC_N(double, (size_t)config->target_count);
    result.count = (size_t)config->target_count;
    
    // Calculate spacing between positions
    double spacing = (config->total_count - 1.0) / (config->target_count > 1 ? config->target_count - 1.0 : 1.0);
    
    // Generate positions with proper rounding and bounds checking
    for (size_t i = 0; i < (size_t)config->target_count; i++) {
        double pos = i * spacing;
        // Round to nearest integer
        pos = floor(pos + 0.5);
        // Ensure within bounds
        if (pos < 0) pos = 0;
        if (pos >= config->total_count) pos = config->total_count - 1;
        result.positions[i] = pos;
    }
    
    return result;
}

// Ruby method for calculating positions
VALUE rb_calculate_positions(VALUE self, VALUE total_count_val, VALUE ratio_val, VALUE available_items_val) {
    (void)self; // Suppress unused parameter warning
    
    // Convert Ruby values to C types
    double total_count = NUM2DBL(total_count_val);
    double ratio = NUM2DBL(ratio_val);
    
    // Handle available_items - can be a number or array
    double available_items;
    double* available_positions = NULL;
    size_t available_positions_count = 0;
    
    if (NIL_P(available_items_val)) {
        available_items = total_count;
    } else if (TYPE(available_items_val) == T_ARRAY) {
        available_positions = rb_ary_to_doubles(available_items_val, &available_positions_count);
        available_items = (double)available_positions_count;
    } else {
        available_items = NUM2DBL(available_items_val);
    }
    
    // Calculate target count based on ratio
    double target_count = total_count * ratio;
    if (target_count > available_items) {
        target_count = available_items;
    }
    
    // Set up configuration
    PositionConfig config = {
        .total_count = total_count,
        .target_count = target_count,
        .available_positions = available_positions,
        .available_positions_count = available_positions_count
    };
    
    // Calculate positions
    PositionResult result = calculate_positions_native(&config);
    
    // Free available positions if allocated
    if (available_positions) {
        xfree(available_positions);
    }
    
    // Handle errors
    if (result.error_code != 0) {
        if (result.error_code == 1) {
            rb_raise(rb_eArgError, "Invalid input: target_count and total_count must be positive");
        } else if (result.error_code == 2) {
            rb_raise(rb_eArgError, "Target count cannot exceed total count");
        }
    }
    
    // Convert result to Ruby array
    VALUE rb_result = doubles_to_rb_ary(result.positions, result.count);
    
    // Free allocated memory
    xfree(result.positions);
    
    return rb_result;
}

// Ruby method for calculating positions using native implementation
VALUE rb_calculate_positions_native(VALUE self, VALUE target_count_val, VALUE available_items_val) {
    (void)self; // Suppress unused parameter warning
    
    // Convert Ruby values to C types
    double target_count = NUM2DBL(target_count_val);
    double available_items = NUM2DBL(available_items_val);
    
    // Set up configuration
    PositionConfig config = {
        .total_count = available_items,
        .target_count = target_count,
        .available_positions = NULL,
        .available_positions_count = 0
    };
    
    // Calculate positions
    PositionResult result = calculate_positions_native(&config);
    
    // Handle errors
    if (result.error_code != 0) {
        if (result.error_code == 1) {
            rb_raise(rb_eArgError, "Invalid input: target_count and total_count must be positive");
        } else if (result.error_code == 2) {
            rb_raise(rb_eArgError, "Target count cannot exceed total count");
        }
    }
    
    // Create a new PositionArray
    position_array* array = create_position_array(result.count);
    if (!array) {
        xfree(result.positions);
        rb_raise(rb_eNoMemError, "Failed to allocate PositionArray");
    }
    
    // Copy positions to the array, ensuring they are integers within bounds
    for (size_t i = 0; i < result.count; i++) {
        // Round to nearest integer
        long pos = (long)floor(result.positions[i] + 0.5);
        // Ensure within bounds
        if (pos < 0) pos = 0;
        if (pos >= (long)config.total_count) pos = (long)config.total_count - 1;
        add_position(array, (double)pos); // Convert back to double since that's what position_array expects
    }
    
    // Free the temporary result array
    xfree(result.positions);
    
    // Wrap the array in a Ruby object
    return TypedData_Wrap_Struct(cPositionArray, &position_array_type, array);
}

// Helper to get the position_array struct from a Ruby object
static position_array* get_position_array(VALUE self) {
    position_array* array;
    TypedData_Get_Struct(self, position_array, &position_array_type, array);
    return array;
}

// Ruby method: size
static VALUE rb_position_array_size(VALUE self) {
    position_array* array = get_position_array(self);
    return SIZET2NUM(get_size(array));
}

// Ruby method: get
static VALUE rb_position_array_get(VALUE self, VALUE index_val) {
    position_array* array = get_position_array(self);
    size_t index = NUM2SIZET(index_val);
    
    if (index >= get_size(array)) {
        rb_raise(rb_eIndexError, "index %zu out of bounds (size: %zu)", index, get_size(array));
    }
    
    // Get position and convert to integer
    double pos = get_position(array, index);
    return LONG2NUM((long)floor(pos + 0.5));
}

// Ruby method: to_a
static VALUE rb_position_array_to_a(VALUE self) {
    position_array* array = get_position_array(self);
    size_t size = get_size(array);
    VALUE result = rb_ary_new_capa(size);
    
    for (size_t i = 0; i < size; i++) {
        double pos = get_position(array, i);
        rb_ary_push(result, LONG2NUM((long)floor(pos + 0.5)));
    }
    
    return result;
}

// Initialize the module
void Init_distributor(void) {
    VALUE mTypeBalancer = rb_define_module("TypeBalancer");
    VALUE mNative = rb_define_module_under(mTypeBalancer, "Native");
    rb_define_singleton_method(mNative, "calculate_positions", rb_calculate_positions, 3);
    rb_define_singleton_method(mNative, "calculate_positions_native", rb_calculate_positions_native, 2);
    
    // Create the PositionArray class under TypeBalancer
    cPositionArray = rb_define_class_under(mTypeBalancer, "PositionArray", rb_cObject);
    
    // Define methods on PositionArray
    rb_define_method(cPositionArray, "size", rb_position_array_size, 0);
    rb_define_method(cPositionArray, "[]", rb_position_array_get, 1);
    rb_define_method(cPositionArray, "to_a", rb_position_array_to_a, 0);
}