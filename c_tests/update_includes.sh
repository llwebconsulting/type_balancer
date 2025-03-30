#!/bin/bash

# Replace direct Ruby includes with our wrapper in all test files
for file in test_*.cpp; do
    if [ -f "$file" ]; then
        # Replace direct Ruby includes with our wrapper
        sed -i '' 's/#include <ruby.h>/#include "ruby_wrapper.h"/' "$file"
        
        # Add wrapper include if file uses Ruby but doesn't have the include
        if grep -q "VALUE" "$file" && ! grep -q "ruby_wrapper.h" "$file"; then
            sed -i '' '1a\
#include "ruby_wrapper.h"
' "$file"
        fi
    fi
done 