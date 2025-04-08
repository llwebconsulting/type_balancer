#include <math.h>
#include <string.h>
#include <stdint.h>
#include "spacing_calculator.h"

#ifdef __APPLE__
#include <TargetConditionals.h>
#endif

// SIMD detection and includes
#if defined(__x86_64__) || defined(_M_X64)
#include <immintrin.h>
#define USE_AVX2 1
#elif defined(__aarch64__) || defined(_M_ARM64)
#include <arm_neon.h>
#define USE_NEON 1
#endif

// Cache line size optimization
#define CACHE_LINE_SIZE 64
#define BATCH_SIZE 16

// Aligned buffer for SIMD operations
typedef struct {
    alignas(CACHE_LINE_SIZE) double values[8];
} aligned_buffer;

// Fast division using SIMD operations
static inline double divide_simd(long numerator, long denominator) {
    if (denominator == 0) return 0.0;
    
    // For power-of-two denominators, use bit shifts
    if ((denominator & (denominator - 1)) == 0) {
        int shift = __builtin_ctzl((unsigned long)denominator);
        return (double)numerator / (1UL << shift);
    }
    
#if defined(USE_AVX2)
    __m256d num_vec = _mm256_set1_pd((double)numerator);
    __m256d denom_vec = _mm256_set1_pd((double)denominator);
    __m256d result = _mm256_div_pd(num_vec, denom_vec);
    alignas(32) double aligned_result[4];
    _mm256_store_pd(aligned_result, result);
    return aligned_result[0];
#elif defined(USE_NEON)
    float64x2_t num_vec = vdupq_n_f64((double)numerator);
    float64x2_t denom_vec = vdupq_n_f64((double)denominator);
    float64x2_t result = vdivq_f64(num_vec, denom_vec);
    alignas(16) double aligned_result[2];
    vst1q_f64(aligned_result, result);
    return aligned_result[0];
#else
    return (double)numerator / denominator;
#endif
}

// SIMD-optimized spacing calculation
static inline double calculate_spacing_simd(long total_count, long target_count) {
    if (total_count <= 1 || target_count <= 1) {
        return 0.0;
    }

    // Optimize common ratios using branchless operations
    uint64_t ratio_match = 0;
    ratio_match |= (target_count == total_count) << 0;
    ratio_match |= (target_count == total_count/2) << 1;
    ratio_match |= (target_count == total_count/3) << 2;
    ratio_match |= (target_count == total_count/4) << 3;
    
    static const double common_ratios[] = {1.0, 2.0, 3.0, 4.0};
    if (ratio_match) {
        int idx = __builtin_ctzl(ratio_match);
        return common_ratios[idx];
    }

    return divide_simd(total_count - 1, target_count - 1);
}

// Main spacing calculation function
double calculate_spacing(long total_count, long target_count) {
    // Fast path using branchless operations
    uint64_t invalid = (total_count <= 0) | (target_count <= 0);
    if (invalid) return 0.0;
    
    uint64_t special_case = (target_count >= total_count) | (target_count == 1);
    if (special_case) {
        return (target_count >= total_count) ? 1.0 : 0.0;
    }

    return calculate_spacing_simd(total_count, target_count);
}

// Batch processing with SIMD optimization
void calculate_spacing_batch(const long* total_counts, const long* target_counts, 
                           double* results, size_t count) {
    if (!total_counts || !target_counts || !results || count == 0) {
        return;
    }

#if defined(USE_AVX2)
    // Process 4 spacings at once with AVX2
    for (size_t i = 0; i < count - 3; i += 4) {
        __m256d tc = _mm256_set_pd(total_counts[i+3] - 1, total_counts[i+2] - 1,
                                  total_counts[i+1] - 1, total_counts[i] - 1);
        __m256d tg = _mm256_set_pd(target_counts[i+3] - 1, target_counts[i+2] - 1,
                                  target_counts[i+1] - 1, target_counts[i] - 1);
        
        // Handle special cases
        __m256d zeros = _mm256_setzero_pd();
        __m256d ones = _mm256_set1_pd(1.0);
        
        // Calculate spacings
        __m256d spacing = _mm256_div_pd(tc, tg);
        
        // Handle special cases with masking
        __m256d tc_mask = _mm256_cmp_pd(tc, zeros, _CMP_GT_OQ);
        __m256d tg_mask = _mm256_cmp_pd(tg, zeros, _CMP_GT_OQ);
        __m256d special_mask = _mm256_and_pd(tc_mask, tg_mask);
        
        spacing = _mm256_blendv_pd(zeros, spacing, special_mask);
        
        // Store results
        _mm256_store_pd(&results[i], spacing);
    }
#elif defined(USE_NEON)
    // Process 2 spacings at once with NEON
    for (size_t i = 0; i < count - 1; i += 2) {
        float64x2_t tc = vld1q_f64((const double*)&total_counts[i]);
        float64x2_t tg = vld1q_f64((const double*)&target_counts[i]);
        
        // Subtract 1 from counts
        tc = vsubq_f64(tc, vdupq_n_f64(1.0));
        tg = vsubq_f64(tg, vdupq_n_f64(1.0));
        
        // Calculate spacings
        float64x2_t spacing = vdivq_f64(tc, tg);
        
        // Handle special cases
        uint64x2_t tc_mask = vcgtq_f64(tc, vdupq_n_f64(0.0));
        uint64x2_t tg_mask = vcgtq_f64(tg, vdupq_n_f64(0.0));
        uint64x2_t special_mask = vandq_u64(tc_mask, tg_mask);
        
        // Blend results
        spacing = vbslq_f64(special_mask, spacing, vdupq_n_f64(0.0));
        
        // Store results
        vst1q_f64(&results[i], spacing);
    }
#endif

    // Handle remaining elements and non-SIMD path
    for (size_t i = (count/4)*4; i < count; i++) {
        results[i] = calculate_spacing(total_counts[i], target_counts[i]);
    }
}

// Batch processing with pre-allocation
void calculate_spacing_batch_preallocated(const long* total_counts, const long* target_counts,
                                        double* results, size_t count, size_t batch_size) {
    if (!total_counts || !target_counts || !results || count == 0) {
        return;
    }

    // Process in batches for better cache utilization
    for (size_t offset = 0; offset < count; offset += batch_size) {
        size_t current_batch = (offset + batch_size <= count) ? batch_size : (count - offset);
        calculate_spacing_batch(&total_counts[offset], &target_counts[offset],
                              &results[offset], current_batch);
    }
} 
