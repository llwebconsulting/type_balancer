#!/usr/bin/env ruby
# frozen_string_literal: true

require 'mkmf'

# Set compiler flags for better optimization and warnings
$CFLAGS << ' -O3 -Wall -Wextra -Wno-unused-parameter'

# Add the current directory to the include path
$CFLAGS << " -I$(srcdir)"

# Add include paths
dir_config('type_balancer')

# Check for required headers
unless have_header('ruby.h')
  puts "Can't find ruby.h"
  exit 1
end

# List all source files
$srcs = %w[
  gap_filler.c
  sequential_filler.c
  alternating_filler.c
  item_queue.c
]

# Create Makefile for the gap fillers extension
create_makefile('type_balancer/gap_fillers') 