#include <gtest/gtest.h>
#include "ruby_wrapper.h"

int main(int argc, char **argv) {
    // Initialize Ruby
    ruby_init();
    ruby_init_loadpath();

    // Run tests
    testing::InitGoogleTest(&argc, argv);
    int result = RUN_ALL_TESTS();

    // Clean up Ruby
    ruby_cleanup(0);

    return result;
} 