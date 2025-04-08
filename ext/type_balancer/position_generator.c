#include <stdlib.h>
#include <string.h>
#include "position_generator.h"
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

// Fast integer division approximation for spacing
static inline long fast_spacing_calc(long total, long count) {
    if (count == 0) return 0;
    if (count == total) return 1;
    if (count == total/2) return 2;
    if (count == total/3) return 3;
    if (count == total/4) return 4;
    return total / count;
}

// SIMD-optimized consecutive position generation
static void generate_consecutive_simd(size_t* data, long count) {
#if defined(USE_AVX2)
    const int simd_width = 4;
    __m256i increment = _mm256_set1_epi64x(simd_width);
    __m256i indices = _mm256_set_epi64x(3, 2, 1, 0);
    
    for (long i = 0; i < count - (simd_width-1); i += simd_width) {
        _mm256_storeu_si256((__m256i*)&data[i], indices);
        indices = _mm256_add_epi64(indices, increment);
    }
#elif defined(USE_NEON)
    const int simd_width = 2;
    int32x2_t increment = vdup_n_s32(simd_width);
    int32x2_t indices = {0, 1};
    
    for (long i = 0; i < count - (simd_width-1); i += simd_width) {
        vst1_s32((int32_t*)&data[i], indices);
        indices = vadd_s32(indices, increment);
    }
#endif

    // Handle remaining elements
    for (long i = (count / 4) * 4; i < count; i++) {
        data[i] = i;
    }
}

position_array *generate_consecutive_positions(long count) {
    if (count <= 0) return NULL;

    position_array *array = create_position_array(count);
    if (!array) return NULL;

    // Direct memory access for better performance
    size_t *data = array->data;
    
    if (count >= 8) {
        generate_consecutive_simd(data, count);
    } else {
        for (long i = 0; i < count; i++) {
            data[i] = i;
        }
    }
    
    array->size = count;
    return array;
}

// SIMD-optimized spaced position generation
static void generate_spaced_simd(size_t* data, long count, double spacing) {
#if defined(USE_AVX2)
    const int simd_width = 4;
    __m256d vec_spacing = _mm256_set1_pd(spacing);
    __m256d vec_indices = _mm256_set_pd(3.0, 2.0, 1.0, 0.0);
    
    for (long i = 0; i < count - (simd_width-1); i += simd_width) {
        __m256d vec_pos = _mm256_mul_pd(vec_indices, vec_spacing);
        __m256i vec_int = _mm256_cvttpd_epi32(vec_pos);
        int32_t tmp[simd_width];
        _mm256_storeu_si256((__m256i*)tmp, vec_int);
        
        for (int j = 0; j < simd_width; j++) {
            data[i + j] = (size_t)tmp[j];
        }
        vec_indices = _mm256_add_pd(vec_indices, _mm256_set1_pd(simd_width));
    }
#elif defined(USE_NEON)
    const int simd_width = 2;
    float32x2_t vec_spacing = vdup_n_f32((float)spacing);
    float32x2_t vec_indices = {0.0f, 1.0f};
    
    for (long i = 0; i < count - (simd_width-1); i += simd_width) {
        float32x2_t vec_pos = vmul_f32(vec_indices, vec_spacing);
        int32x2_t vec_int = vcvt_s32_f32(vec_pos);
        int32_t tmp[simd_width];
        vst1_s32(tmp, vec_int);
        
        for (int j = 0; j < simd_width; j++) {
            data[i + j] = (size_t)tmp[j];
        }
        vec_indices = vadd_f32(vec_indices, vdup_n_f32(simd_width));
    }
#endif

    // Handle remaining elements
    double current = (count / 4) * 4 * spacing;
    for (long i = (count / 4) * 4; i < count; i++) {
        data[i] = (size_t)current;
        current += spacing;
    }
}

position_array *generate_spaced_positions(long total_count, double spacing, long target_count) {
    if (total_count <= 0 || spacing <= 0 || target_count <= 0) return NULL;

    position_array *array = create_position_array(target_count);
    if (!array) return NULL;

    // Direct memory access for better performance
    size_t *data = array->data;
    
    if (target_count >= 8) {
        generate_spaced_simd(data, target_count, spacing);
    } else {
        double current = 0;
        for (long i = 0; i < target_count; i++) {
            data[i] = (size_t)current;
            current += spacing;
        }
    }
    
    // Ensure positions don't exceed total_count
    for (long i = 0; i < target_count; i++) {
        if (data[i] >= (size_t)total_count) {
            data[i] = total_count - 1;
        }
    }
    
    array->size = target_count;
    return array;
}

position_array *generate_positions(long total_count, long target_count) {
    if (total_count <= 0 || target_count <= 0 || target_count > total_count) {
        return NULL;
    }

    position_array *array = create_position_array(target_count);
    if (!array) return NULL;

    // Direct memory access for better performance
    size_t *data = array->data;

    if (target_count == total_count) {
        // Use SIMD for consecutive positions
        if (target_count >= 8) {
            generate_consecutive_simd(data, target_count);
        } else {
            for (long i = 0; i < total_count; i++) {
                data[i] = i;
            }
        }
    } else {
        // Calculate spacing between positions using fast integer math
        long spacing = fast_spacing_calc(total_count, target_count);
        long remainder = total_count % target_count;
        
        if (target_count >= 8 && remainder == 0) {
            // Use SIMD for evenly spaced positions
            generate_spaced_simd(data, target_count, spacing);
        } else {
            // Handle uneven spacing
            size_t current_pos = 0;
            for (long i = 0; i < target_count; i++) {
                data[i] = current_pos;
                current_pos += spacing + (i < remainder ? 1 : 0);
            }
        }
    }
    
    array->size = target_count;
    return array;
}

void calculate_spaced_positions(position_array *positions, size_t collection_size, size_t item_count) {
    if (!positions || collection_size == 0 || item_count == 0) {
        return;
    }

    // Calculate spacing between items using fast integer math when possible
    double spacing;
    if (item_count == collection_size) {
        spacing = 1.0;
    } else if (item_count == collection_size/2) {
        spacing = 2.0;
    } else if (item_count == collection_size/3) {
        spacing = 3.0;
    } else if (item_count == collection_size/4) {
        spacing = 4.0;
    } else {
        spacing = calculate_spacing((long)collection_size, (long)item_count);
    }
    
    // Use SIMD for larger arrays
    if (item_count >= 8) {
        generate_spaced_simd(positions->data, item_count, spacing);
        positions->size = item_count;
    } else {
        // Direct memory access for small arrays
        size_t *data = positions->data;
        double current = 0;
        for (size_t i = 0; i < item_count && current < collection_size; i++) {
            data[i] = (size_t)current;
            current += spacing;
        }
        positions->size = item_count;
    }
} 