#include <stdlib.h>
#include <string.h>
#include "position_adjuster.h"

#ifdef __APPLE__
#include <TargetConditionals.h>
#endif

// SIMD detection and includes
#if defined(__x86_64__) || defined(_M_X64)
#include <immintrin.h>
#elif defined(__aarch64__)
#include <arm_neon.h>
#endif

// CPU feature detection
#if defined(__x86_64__) || defined(_M_X64)
static inline int has_sse2() {
    return __builtin_cpu_supports("sse2");
}

static inline int has_avx2() {
    return __builtin_cpu_supports("avx2");
}
#endif

// Adjust positions that exceed bounds
AdjustResult adjust_positions(AdjustConfig* config) {
    if (!config || !config->positions || config->count <= 0 || config->total_count <= 0) {
        return ADJUST_INVALID_INPUT;
    }

    int adjusted = 0;
    for (long i = 0; i < config->count; i++) {
        // Skip if position is already within bounds
        if (config->positions[i] < config->total_count) {
            continue;
        }

        // Find the nearest available position
        long new_pos = config->total_count - 1;
        while (new_pos >= 0) {
            int position_taken = 0;
            
            // Check if position is already taken
            for (long j = 0; j < i; j++) {
                if (config->positions[j] == new_pos) {
                    position_taken = 1;
                    break;
                }
            }

            if (!position_taken) {
                config->positions[i] = new_pos;
                adjusted = 1;
                break;
            }
            new_pos--;
        }

        // If no position found, return error
        if (new_pos < 0) {
            return ADJUST_NO_SPACE;
        }
    }

    return adjusted ? ADJUST_MODIFIED : ADJUST_UNCHANGED;
}

// SIMD-optimized position redistribution for AVX2
#if defined(__x86_64__) || defined(_M_X64)
static int redistribute_positions_avx2(long* positions, long count, long total_count) {
    int modified = 0;
    double spacing = (double)(total_count - 1) / (double)(count - 1);
    __m256d vec_spacing = _mm256_set1_pd(spacing);
    __m256d vec_half = _mm256_set1_pd(0.5);
    
    // Process 4 positions at a time
    for (long i = 0; i < count - 3; i += 4) {
        __m256d vec_indices = _mm256_set_pd(i+3, i+2, i+1, i);
        __m256d vec_ideal = _mm256_mul_pd(vec_indices, vec_spacing);
        vec_ideal = _mm256_add_pd(vec_ideal, vec_half);
        
        // Convert to integers
        __m256i vec_new_pos = _mm256_cvttpd_epi32(vec_ideal);
        long new_positions[4];
        _mm256_storeu_si256((__m256i*)new_positions, vec_new_pos);
        
        // Update positions and track modifications
        for (int j = 0; j < 4; j++) {
            if (positions[i + j] != new_positions[j]) {
                positions[i + j] = new_positions[j];
                modified = 1;
            }
        }
    }
    return modified;
}

// SIMD-optimized position redistribution for SSE2
static int redistribute_positions_sse2(long* positions, long count, long total_count) {
    int modified = 0;
    double spacing = (double)(total_count - 1) / (double)(count - 1);
    __m128d vec_spacing = _mm_set1_pd(spacing);
    __m128d vec_half = _mm_set1_pd(0.5);
    
    // Process 2 positions at a time
    for (long i = 0; i < count - 1; i += 2) {
        __m128d vec_indices = _mm_set_pd(i+1, i);
        __m128d vec_ideal = _mm_mul_pd(vec_indices, vec_spacing);
        vec_ideal = _mm_add_pd(vec_ideal, vec_half);
        
        // Convert to integers
        __m128i vec_new_pos = _mm_cvttpd_epi32(vec_ideal);
        long new_positions[2];
        _mm_storeu_si128((__m128i*)new_positions, vec_new_pos);
        
        // Update positions and track modifications
        for (int j = 0; j < 2; j++) {
            if (positions[i + j] != new_positions[j]) {
                positions[i + j] = new_positions[j];
                modified = 1;
            }
        }
    }
    return modified;
}
#elif defined(__aarch64__)
// SIMD-optimized position redistribution for NEON
static int redistribute_positions_neon(long* positions, long count, long total_count) {
    int modified = 0;
    double spacing = (double)(total_count - 1) / (double)(count - 1);
    float64x2_t vec_spacing = vdupq_n_f64(spacing);
    float64x2_t vec_half = vdupq_n_f64(0.5);
    
    // Process 2 positions at a time
    for (long i = 0; i < count - 1; i += 2) {
        float64x2_t vec_indices = {(double)i, (double)(i+1)};
        float64x2_t vec_ideal = vmulq_f64(vec_indices, vec_spacing);
        vec_ideal = vaddq_f64(vec_ideal, vec_half);
        
        // Convert to integers and store
        int64x2_t vec_new_pos = vcvtq_s64_f64(vec_ideal);
        int64_t temp_positions[2];
        vst1q_s64(temp_positions, vec_new_pos);
        
        // Copy to output array with proper type casting
        for (int j = 0; j < 2; j++) {
            long new_pos = (long)temp_positions[j];
            if (positions[i + j] != new_pos) {
                positions[i + j] = new_pos;
                modified = 1;
            }
        }
    }
    return modified;
}
#endif

// Scalar fallback for position redistribution
static int redistribute_positions_scalar(long* positions, long count, long total_count) {
    int modified = 0;
    double spacing = (double)(total_count - 1) / (double)(count - 1);
    
    for (long i = 0; i < count; i++) {
        double ideal_pos = i * spacing;
        long new_pos = (long)(ideal_pos + 0.5); // Round to nearest integer
        
        if (positions[i] != new_pos) {
            positions[i] = new_pos;
            modified = 1;
        }
    }
    
    return modified;
}

// Redistribute positions to maintain even spacing
AdjustResult redistribute_positions(AdjustConfig* config) {
    if (!config || !config->positions || config->count <= 0 || config->total_count <= 0) {
        return ADJUST_INVALID_INPUT;
    }

    // No need to redistribute if we have 0 or 1 position
    if (config->count <= 1) {
        return ADJUST_UNCHANGED;
    }

    int modified = 0;

    // Choose the best available method
#if defined(__x86_64__) || defined(_M_X64)
    if (has_avx2()) {
        modified = redistribute_positions_avx2(config->positions, config->count, config->total_count);
        // Handle remaining positions
        long remaining_start = (config->count / 4) * 4;
        if (remaining_start < config->count) {
            modified |= redistribute_positions_scalar(config->positions + remaining_start, 
                                                   config->count - remaining_start, 
                                                   config->total_count);
        }
    } else if (has_sse2()) {
        modified = redistribute_positions_sse2(config->positions, config->count, config->total_count);
        // Handle remaining positions
        long remaining_start = (config->count / 2) * 2;
        if (remaining_start < config->count) {
            modified |= redistribute_positions_scalar(config->positions + remaining_start, 
                                                   config->count - remaining_start, 
                                                   config->total_count);
        }
    } else {
        modified = redistribute_positions_scalar(config->positions, config->count, config->total_count);
    }
#elif defined(__aarch64__)
    modified = redistribute_positions_neon(config->positions, config->count, config->total_count);
    // Handle remaining positions
    long remaining_start = (config->count / 2) * 2;
    if (remaining_start < config->count) {
        modified |= redistribute_positions_scalar(config->positions + remaining_start, 
                                               config->count - remaining_start, 
                                               config->total_count);
    }
#else
    modified = redistribute_positions_scalar(config->positions, config->count, config->total_count);
#endif

    return modified ? ADJUST_MODIFIED : ADJUST_UNCHANGED;
} 