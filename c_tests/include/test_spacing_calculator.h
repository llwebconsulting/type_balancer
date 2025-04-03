#ifndef TEST_SPACING_CALCULATOR_H
#define TEST_SPACING_CALCULATOR_H

#ifdef __cplusplus
extern "C" {
#endif

// Calculate the base spacing between positions
double calculate_base_spacing(int total_count, int target_count);

// Adjust spacing for edge cases and special conditions
double adjust_spacing_for_edge_cases(double spacing, int total_count, int target_count);

// Calculate the final spacing value considering all factors
double calculate_spacing(int total_count, int target_count);

#ifdef __cplusplus
}
#endif

#endif // TEST_SPACING_CALCULATOR_H 