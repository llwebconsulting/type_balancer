#!/bin/bash

# Create wrapped headers directory if it doesn't exist
mkdir -p include/wrapped

# Function to create a wrapped header
create_wrapped_header() {
    local header=$1
    local base_name=$(basename "$header")
    local wrapped_file="include/wrapped/${base_name}"
    
    echo "#ifndef WRAPPED_${base_name%.*}_H" > "$wrapped_file"
    echo "#define WRAPPED_${base_name%.*}_H" >> "$wrapped_file"
    echo "" >> "$wrapped_file"
    echo "#include \"ruby_wrapper.h\"" >> "$wrapped_file"
    echo "" >> "$wrapped_file"
    echo "extern \"C\" {" >> "$wrapped_file"
    echo "    #include \"../../../ext/type_balancer/${base_name}\"" >> "$wrapped_file"
    echo "}" >> "$wrapped_file"
    echo "" >> "$wrapped_file"
    echo "#endif // WRAPPED_${base_name%.*}_H" >> "$wrapped_file"
}

# Create wrapped versions of all headers that include Ruby
for header in ../ext/type_balancer/*.h; do
    if grep -q "ruby.h" "$header"; then
        create_wrapped_header "$(basename "$header")"
    fi
done

# Update test files to use wrapped headers
for test_file in test_*.cpp; do
    if [ -f "$test_file" ]; then
        # Get the base name of the test file (e.g., test_position_calculator.cpp -> position_calculator)
        base_name=${test_file#test_}
        base_name=${base_name%.cpp}
        header_name="${base_name}.h"
        
        # If the original header includes Ruby, update the test to use the wrapped version
        if [ -f "include/wrapped/${header_name}" ]; then
            sed -i '' "s|#include \".*${header_name}\"|#include \"wrapped/${header_name}\"|" "$test_file"
        fi
    fi
done 