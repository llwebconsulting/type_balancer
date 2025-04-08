#!/usr/bin/env ruby
# frozen_string_literal: true

require 'mkmf'

# Add CFLAGS for optimization and warnings
$CFLAGS << ' -Wall -Wextra -O3'

# Check for required headers
have_header('ruby.h')
have_header('ruby/thread.h')

# Check for math library
have_library('m', 'ceil')

# Create header with function exports
File.write('function_exports.h', <<~HEADER)
  #ifndef FUNCTION_EXPORTS_H
  #define FUNCTION_EXPORTS_H

  #include "position_calculator.h"

  // Export batch processing function
  __attribute__((visibility("default")))
  int calculate_positions_batch(struct position_batch* batch, int iterations, long* positions, int* result_size);

  #endif /* FUNCTION_EXPORTS_H */
HEADER

# Create a single Makefile for the combined extension
create_makefile('type_balancer/type_balancer')
