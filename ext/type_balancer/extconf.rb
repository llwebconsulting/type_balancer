#!/usr/bin/env ruby
# frozen_string_literal: true

require 'mkmf'

# Check for required headers
have_header('ruby.h')
have_header('ruby/thread.h')

# Add compiler flags
$CFLAGS << ' -Wall -Wextra -O3'
$CFLAGS << ' -I$(srcdir)'

# Enable SIMD optimizations where available
if RUBY_PLATFORM =~ /x86_64|amd64/
  $CFLAGS << ' -mavx2' if try_cflags('-mavx2')
  $CFLAGS << ' -msse2' if try_cflags('-msse2')
elsif RUBY_PLATFORM =~ /arm|aarch64/
  $CFLAGS << ' -march=armv8-a+simd' if try_cflags('-march=armv8-a+simd')
end

# List all source files explicitly
srcs = %w[
  init.c
  position_array.c
  position_calculator.c
  position_adjuster.c
  sequential_filler.c
  item_queue.c
  alternating_filler.c
  distributor.c
  gap_filler.c
  position_generator.c
  spacing_calculator.c
]

# Create makefile with the correct extension name
dir_config('type_balancer')
create_makefile('type_balancer/native')
