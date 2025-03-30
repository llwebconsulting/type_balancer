#include <gtest/gtest.h>
#include "wrapped/distributor.h"
#include "ruby_wrapper.h"

class DistributorTest : public ::testing::Test {
protected:
    void SetUp() override {
        // Initialize test data
        total_count = 10;
        available_items = 4;
        target_ratio = 0.4;
    }

    long total_count;
    long available_items;
    double target_ratio;
};

TEST_F(DistributorTest, CalculateTargetPositions) {
    PositionConfig config = {
        .total_count = total_count,
        .target_count = (long)(total_count * target_ratio)
    };

    PositionResult result = calculate_positions(&config);
    ASSERT_NE(nullptr, result.positions);
    EXPECT_EQ(0, result.error_code);
    EXPECT_EQ(4, result.count);  // 40% of 10 = 4 positions

    // Check position spacing
    EXPECT_EQ(0, result.positions[0]);
    EXPECT_EQ(3, result.positions[1]);
    EXPECT_EQ(6, result.positions[2]);
    EXPECT_EQ(9, result.positions[3]);

    free_position_result(&result);
}

TEST_F(DistributorTest, HandleInvalidConfig) {
    PositionConfig config = {
        .total_count = -1,  // Invalid
        .target_count = 5
    };

    PositionResult result = calculate_positions(&config);
    EXPECT_NE(0, result.error_code);
    EXPECT_EQ(nullptr, result.positions);
}

TEST_F(DistributorTest, HandleZeroTargetCount) {
    PositionConfig config = {
        .total_count = total_count,
        .target_count = 0
    };

    PositionResult result = calculate_positions(&config);
    EXPECT_EQ(0, result.error_code);
    EXPECT_EQ(0, result.count);
}

TEST_F(DistributorTest, HandleLargeInput) {
    PositionConfig config = {
        .total_count = 1000000,
        .target_count = 1000
    };

    PositionResult result = calculate_positions(&config);
    ASSERT_NE(nullptr, result.positions);
    EXPECT_EQ(0, result.error_code);
    EXPECT_EQ(1000, result.count);

    // Check first and last positions
    EXPECT_EQ(0, result.positions[0]);
    EXPECT_LT(result.positions[result.count - 1], 1000000);

    free_position_result(&result);
}

TEST_F(DistributorTest, HandleMemoryAllocationFailure) {
    PositionConfig config = {
        .total_count = LONG_MAX,
        .target_count = LONG_MAX
    };

    PositionResult result = calculate_positions(&config);
    EXPECT_NE(0, result.error_code);
    EXPECT_EQ(nullptr, result.positions);
}

TEST_F(DistributorTest, EnsureThreadSafety) {
    PositionConfig config = {
        .total_count = total_count,
        .target_count = (long)(total_count * target_ratio)
    };

    // Run multiple calculations in parallel to test thread safety
    #pragma omp parallel for
    for (int i = 0; i < 100; i++) {
        PositionResult result = calculate_positions(&config);
        ASSERT_NE(nullptr, result.positions);
        EXPECT_EQ(0, result.error_code);
        EXPECT_EQ(4, result.count);
        free_position_result(&result);
    }
}


