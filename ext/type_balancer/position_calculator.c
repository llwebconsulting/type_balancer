#include "position_calculator.h"
#include <ruby.h>
#include <math.h>
#include <stdlib.h>

#ifdef __AVX2__
#include <immintrin.h>
#endif

#ifdef __ARM_NEON
#include <arm_neon.h>
#endif

// Calculate target count based on total count and ratio
long calculate_target_count(long total_count, long available_items, double target_ratio) {
    if (total_count <= 0 || available_items <= 0 || target_ratio <= 0.0 || target_ratio > 1.0) {
        return 0;
    }
    
    double target = total_count * target_ratio;
    long result = (long)round(target);
    return result > available_items ? available_items : result;
}

// Calculate positions using SIMD when available
PositionResult calculate_positions(const PositionConfig* config) {
    PositionResult result = {NULL, 0, POSITION_INVALID_INPUT};
    
    if (!config || config->total_count <= 0 || config->target_count <= 0) {
        return result;
    }
    
    result.positions = (double*)malloc(config->target_count * sizeof(double));
    if (!result.positions) {
        result.error_code = POSITION_MEMORY_ERROR;
        return result;
    }
    
    double spacing = (double)config->total_count / (double)config->target_count;
    double current = spacing / 2.0;
    
#ifdef __AVX2__
    // Process 4 positions at a time using AVX2
    const int simd_width = 4;
    __m256d vec_spacing = _mm256_set1_pd(spacing);
    __m256d vec_current = _mm256_set_pd(current + spacing * 3, current + spacing * 2,
                                       current + spacing, current);
    
    int i;
    for (i = 0; i + simd_width <= config->target_count; i += simd_width) {
        _mm256_storeu_pd(&result.positions[i], vec_current);
        vec_current = _mm256_add_pd(vec_current, _mm256_set1_pd(spacing * simd_width));
    }
    
    // Handle remaining positions
    current += spacing * i;
#elif defined(__ARM_NEON)
    // Process 2 positions at a time using NEON
    const int simd_width = 2;
    float64x2_t vec_spacing = vdupq_n_f64(spacing);
    float64x2_t vec_current = vsetq_lane_f64(current + spacing, vdupq_n_f64(current), 1);
    
    int i;
    for (i = 0; i + simd_width <= config->target_count; i += simd_width) {
        vst1q_f64(&result.positions[i], vec_current);
        vec_current = vaddq_f64(vec_current, vmulq_n_f64(vec_spacing, simd_width));
    }
    
    // Handle remaining positions
    current += spacing * i;
#else
    int i = 0;
#endif
    
    // Handle remaining positions
    for (; i < config->target_count; i++) {
        result.positions[i] = current;
        current += spacing;
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