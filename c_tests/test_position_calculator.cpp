#include <gtest/gtest.h>
#include "wrapped/position_calculator.h"

class PositionCalculatorTest : public ::testing::Test {
protected:
    void SetUp() override {}
    void TearDown() override {}
};

TEST_F(PositionCalculatorTest, CalculateTargetCount) {
    // Test normal case
    EXPECT_EQ(4, calculate_target_count(10, 5, 0.4));
    
    // Test rounding
    EXPECT_EQ(3, calculate_target_count(10, 5, 0.25));
    
    // Test minimum of one position for positive ratio
    EXPECT_EQ(1, calculate_target_count(10, 5, 0.01));
    
    // Test limited by available items
    EXPECT_EQ(3, calculate_target_count(10, 3, 0.5));
    
    // Test limited by total count
    EXPECT_EQ(5, calculate_target_count(5, 10, 1.0));
}

TEST_F(PositionCalculatorTest, CalculateTargetCountInvalidInputs) {
    // Test invalid inputs return 0
    EXPECT_EQ(0, calculate_target_count(-1, 5, 0.4));
    EXPECT_EQ(0, calculate_target_count(10, -1, 0.4));
    EXPECT_EQ(0, calculate_target_count(10, 5, -0.1));
    EXPECT_EQ(0, calculate_target_count(10, 5, 1.1));
    EXPECT_EQ(0, calculate_target_count(0, 5, 0.4));
}

TEST_F(PositionCalculatorTest, CalculatePositionsNormalCase) {
    PositionConfig config = {
        .total_count = 10,
        .target_count = 4
    };
    
    PositionResult result = calculate_positions(&config);
    ASSERT_NE(nullptr, result.positions);
    EXPECT_EQ(4, result.count);
    EXPECT_EQ(0, result.error_code);
    
    // Check evenly spaced positions
    EXPECT_EQ(0, result.positions[0]);
    EXPECT_EQ(3, result.positions[1]);
    EXPECT_EQ(6, result.positions[2]);
    EXPECT_EQ(9, result.positions[3]);
    
    free_position_result(&result);
}

TEST_F(PositionCalculatorTest, CalculatePositionsSingleItem) {
    PositionConfig config = {
        .total_count = 5,
        .target_count = 1
    };
    
    PositionResult result = calculate_positions(&config);
    ASSERT_NE(nullptr, result.positions);
    EXPECT_EQ(1, result.count);
    EXPECT_EQ(0, result.error_code);
    EXPECT_EQ(0, result.positions[0]);
    
    free_position_result(&result);
}

TEST_F(PositionCalculatorTest, CalculatePositionsAllPositions) {
    PositionConfig config = {
        .total_count = 3,
        .target_count = 3
    };
    
    PositionResult result = calculate_positions(&config);
    ASSERT_NE(nullptr, result.positions);
    EXPECT_EQ(3, result.count);
    EXPECT_EQ(0, result.error_code);
    
    // Should be consecutive positions
    EXPECT_EQ(0, result.positions[0]);
    EXPECT_EQ(1, result.positions[1]);
    EXPECT_EQ(2, result.positions[2]);
    
    free_position_result(&result);
}

TEST_F(PositionCalculatorTest, CalculatePositionsInvalidInput) {
    // Test null config
    PositionResult result = calculate_positions(nullptr);
    EXPECT_EQ(nullptr, result.positions);
    EXPECT_EQ(0, result.count);
    EXPECT_EQ(1, result.error_code);
    
    // Test invalid counts
    PositionConfig invalid_config = {
        .total_count = -1,
        .target_count = 1
    };
    result = calculate_positions(&invalid_config);
    EXPECT_EQ(nullptr, result.positions);
    EXPECT_EQ(0, result.count);
    EXPECT_EQ(1, result.error_code);
    
    invalid_config.total_count = 5;
    invalid_config.target_count = -1;
    result = calculate_positions(&invalid_config);
    EXPECT_EQ(nullptr, result.positions);
    EXPECT_EQ(0, result.count);
    EXPECT_EQ(1, result.error_code);
    
    // Test target_count > total_count
    invalid_config.total_count = 3;
    invalid_config.target_count = 5;
    result = calculate_positions(&invalid_config);
    EXPECT_EQ(nullptr, result.positions);
    EXPECT_EQ(0, result.count);
    EXPECT_EQ(1, result.error_code);
}


