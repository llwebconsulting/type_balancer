#include "position_calculator.h"
#include "function_exports.h"
#include <ruby.h>
#include <ruby/thread.h>
#include <math.h>
#include <stdlib.h>

#ifdef __AVX2__
#include <immintrin.h>
#endif

#ifdef __ARM_NEON
#include <arm_neon.h>
#endif

// Calculate target count based on total count and ratio
double calculate_target_count(double total_count, double available_items, double target_ratio) {
    if (total_count <= 0 || available_items <= 0 || target_ratio < 0 || target_ratio > 1) {
        return 0;
    }

    double target = total_count * target_ratio;
    return target > available_items ? available_items : target;
}

// Find closest available position to target
static double find_closest_position(double target, const double* available_positions, size_t count) {
    if (!available_positions || count == 0) return target;
    
    double closest = available_positions[0];
    double min_distance = fabs(target - closest);
    
    for (size_t i = 1; i < count; i++) {
        double distance = fabs(target - available_positions[i]);
        if (distance < min_distance) {
            min_distance = distance;
            closest = available_positions[i];
        }
    }
    
    return closest;
}

// Calculate positions using SIMD when available
PositionResult calculate_positions(const PositionConfig* config) {
    PositionResult result = {NULL, 0, POSITION_INVALID_INPUT};
    
    if (!config || config->total_count <= 0 || config->target_count <= 0 ||
        !config->available_positions || config->available_positions_count == 0) {
        return result;
    }
    
    result.positions = (double*)malloc(config->target_count * sizeof(double));
    if (!result.positions) {
        result.error_code = POSITION_MEMORY_ERROR;
        return result;
    }
    
    double total_space = (double)config->total_count - 1.0;
    double target_spacing = total_space / (double)(config->target_count - 1);
    
    for (long i = 0; i < config->target_count; i++) {
        double target_position = i * target_spacing;
        result.positions[i] = find_closest_position(target_position, 
                                                  config->available_positions,
                                                  config->available_positions_count);
    }
    
    result.count = config->target_count;
    result.error_code = POSITION_SUCCESS;
    return result;
}

void free_position_result(PositionResult* result) {
    if (result && result->positions) {
        free(result->positions);
        result->positions = NULL;
        result->count = 0;
    }
}

// Function to calculate positions in batch mode
int calculate_positions_batch(struct position_batch* batch, int iterations, double* positions, int* result_size) {
    if (!batch || !positions || !result_size || iterations <= 0) {
        return POSITION_INVALID_INPUT;
    }

    *result_size = 0;
    for (int i = 0; i < iterations; i++) {
        double target = calculate_target_count(batch[i].total_count, batch[i].available_count, batch[i].ratio);
        if (target <= 0) continue;

        PositionConfig config = {
            .total_count = batch[i].total_count,
            .target_count = target,
            .available_positions = NULL,
            .available_positions_count = 0
        };

        PositionResult result = calculate_positions(&config);
        if (result.error_code != POSITION_SUCCESS) {
            free_position_result(&result);
            return result.error_code;
        }

        // Copy positions to output array
        for (size_t j = 0; j < result.count; j++) {
            positions[*result_size + j] = result.positions[j];
        }
        *result_size += (int)result.count;

        free_position_result(&result);
    }

    return POSITION_SUCCESS;
}

// Ruby interface
VALUE calculate_target_positions(VALUE self, VALUE total_count, VALUE available_count) {
    (void)self; // Unused parameter

    Check_Type(total_count, T_FIXNUM);
    Check_Type(available_count, T_FIXNUM);

    double total = (double)FIX2LONG(total_count);
    double available = (double)FIX2LONG(available_count);
    double target = calculate_target_count(total, available, 0.5); // Using 0.5 as default ratio

    PositionConfig config = {
        .total_count = total,
        .target_count = target,
        .available_positions = NULL,
        .available_positions_count = 0
    };

    PositionResult result = calculate_positions(&config);
    if (result.error_code != POSITION_SUCCESS) {
        free_position_result(&result);
        rb_raise(rb_eRuntimeError, "Failed to calculate positions");
        return Qnil;
    }

    VALUE positions = rb_ary_new2((long)result.count);
    for (size_t i = 0; i < result.count; i++) {
        rb_ary_push(positions, DBL2NUM(result.positions[i]));
    }

    free_position_result(&result);
    return positions;
}

void Init_position_calculator(void) {
    VALUE mTypeBalancer = rb_define_module("TypeBalancer");
    rb_define_singleton_method(mTypeBalancer, "calculate_target_positions", calculate_target_positions, 2);
} 