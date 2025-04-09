// Position calculator interface
// Responsible for calculating initial position distributions

#ifndef USERS_ANON_GEMS_TYPE_BALANCER_EXT_TYPE_BALANCER_POSITION_CALCULATOR_H
#define USERS_ANON_GEMS_TYPE_BALANCER_EXT_TYPE_BALANCER_POSITION_CALCULATOR_H

#include <stddef.h>
#include <ruby.h>

// Error codes for position calculation
#define POSITION_SUCCESS 0
#define POSITION_INVALID_INPUT 1
#define POSITION_MEMORY_ERROR 2

// Configuration for position calculation
typedef struct {
    double total_count;    // Total number of positions available
    double target_count;   // Number of positions to calculate
    double* available_positions;  // Array of available positions
    size_t available_positions_count;  // Number of available positions
} PositionConfig;

// Result structure for position calculation
typedef struct {
    double* positions;   // Array of calculated positions
    size_t count;       // Number of positions in the array
    int error_code;     // Error code (0 for success)
} PositionResult;

// Structure for batch processing
struct position_batch {
    double total_count;
    double available_count;
    double ratio;
};

// Function declarations
void Init_position_calculator(void);
VALUE calculate_target_positions(VALUE self, VALUE total_count, VALUE available_count);

// Calculate target count based on total count and ratio
// Returns calculated target count, respecting available_items limit
double calculate_target_count(double total_count, double available_items, double target_ratio);

// Calculate positions based on configuration
PositionResult calculate_positions(const PositionConfig* config);

// Free resources associated with a position result
void free_position_result(PositionResult* result);

// Batch processing function
int calculate_positions_batch(struct position_batch* batch, int iterations, double* positions, int* result_size);

#endif /* USERS_ANON_GEMS_TYPE_BALANCER_EXT_TYPE_BALANCER_POSITION_CALCULATOR_H */ 
