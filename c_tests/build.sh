#!/bin/bash

# Clean and create build directory
rm -rf build
mkdir build
cd build

# Set environment variable to disable Werror
export DISABLE_WERROR=1

# Configure with CMake
if [[ "$*" == *"--coverage"* ]]; then
    cmake -DCOVERAGE=ON ..
else
    # Explicitly disable Werror
    CFLAGS="-Wno-error" CXXFLAGS="-Wno-error" cmake -DCMAKE_C_FLAGS="-Wno-error" -DCMAKE_CXX_FLAGS="-Wno-error" .. > /dev/null
fi

# Set custom flags to disable problematic warnings
export CFLAGS="-Wno-compound-token-split-by-macro -Wno-error"
export CXXFLAGS="-Wno-compound-token-split-by-macro -Wno-error"

# Build
make "CFLAGS=-Wno-error" "CXXFLAGS=-Wno-error" > /dev/null

# Run tests
if [ -n "$1" ] && [[ "$1" != "--coverage" ]]; then
    # Run specific test if provided
    ./type_balancer_tests --gtest_filter="$1"
else
    # Run all tests if no test name provided
    ./type_balancer_tests
fi

# Generate coverage report if requested
if [[ "$*" == *"--coverage"* ]]; then
    lcov --capture --directory . --output-file coverage.info
    lcov --remove coverage.info '/usr/*' --output-file coverage.info
    lcov --remove coverage.info '*_test.cpp' --output-file coverage.info
    genhtml coverage.info --output-directory coverage_report
fi 