#include <gtest/gtest.h>
#include "test_spacing_calculator.h"

class SpacingCalculatorTest : public ::testing::Test {
protected:
    void SetUp() override {}
    void TearDown() override {}
};

// Base Spacing Tests
TEST_F(SpacingCalculatorTest, CalculateBaseSpacing) {
    // Test empty or single-item collections
    EXPECT_DOUBLE_EQ(0.0, calculate_base_spacing(0, 0));
    EXPECT_DOUBLE_EQ(0.0, calculate_base_spacing(1, 1));
    EXPECT_DOUBLE_EQ(0.0, calculate_base_spacing(0, 1));
    EXPECT_DOUBLE_EQ(0.0, calculate_base_spacing(1, 0));

    // Test normal cases
    EXPECT_DOUBLE_EQ(1.0, calculate_base_spacing(2, 2));
    EXPECT_DOUBLE_EQ(2.0, calculate_base_spacing(3, 2));
    EXPECT_DOUBLE_EQ(3.0, calculate_base_spacing(4, 2));
}

// Edge Case Adjustment Tests
TEST_F(SpacingCalculatorTest, AdjustSpacingForEdgeCases) {
    // Test small collections
    EXPECT_DOUBLE_EQ(0.0, adjust_spacing_for_edge_cases(1.0, 2, 2));
    EXPECT_DOUBLE_EQ(0.0, adjust_spacing_for_edge_cases(1.0, 1, 1));

    // Test size 3 collection with target 2
    EXPECT_DOUBLE_EQ(2.0, adjust_spacing_for_edge_cases(2.0, 3, 2));

    // Test spacing exceeding total_count
    EXPECT_DOUBLE_EQ(4.0, adjust_spacing_for_edge_cases(5.0, 5, 2));
}

// Final Spacing Calculation Tests
TEST_F(SpacingCalculatorTest, CalculateSpacing) {
    // Test empty or single-item collections
    EXPECT_DOUBLE_EQ(0.0, calculate_spacing(0, 0));
    EXPECT_DOUBLE_EQ(0.0, calculate_spacing(1, 1));
    EXPECT_DOUBLE_EQ(0.0, calculate_spacing(0, 1));
    EXPECT_DOUBLE_EQ(0.0, calculate_spacing(1, 0));

    // Test normal cases
    EXPECT_DOUBLE_EQ(0.0, calculate_spacing(2, 2));  // Edge case: size 2
    EXPECT_DOUBLE_EQ(2.0, calculate_spacing(3, 2));  // Special case: size 3, target 2
    EXPECT_DOUBLE_EQ(3.0, calculate_spacing(4, 2));  // Normal case
} 