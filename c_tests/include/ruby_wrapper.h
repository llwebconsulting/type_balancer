#ifndef RUBY_WRAPPER_H
#define RUBY_WRAPPER_H

// Disable register storage class warnings for Ruby headers
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wregister"

// Ruby defines a lot of C stuff that doesn't play well with C++
#ifdef __cplusplus
// Undefine problematic macros that might be defined elsewhere
#  undef RUBY_EXTERN
#  undef RUBY_SYMBOL_EXPORT_BEGIN
#  undef RUBY_SYMBOL_EXPORT_END
#  undef EXTERN
#  undef BEGIN_EXTERN_C
#  undef END_EXTERN_C
#  undef EXTERN_C

// Define our own extern "C" handling
#  define RUBY_EXTERN extern "C"
#  define RUBY_SYMBOL_EXPORT_BEGIN RUBY_EXTERN {
#  define RUBY_SYMBOL_EXPORT_END }
#  define BEGIN_EXTERN_C RUBY_EXTERN {
#  define END_EXTERN_C }
#  define EXTERN_C RUBY_EXTERN
#endif

// Include Ruby headers
#include <ruby.h>

#ifdef __cplusplus
// Clean up our macros
#  undef RUBY_EXTERN
#  undef RUBY_SYMBOL_EXPORT_BEGIN
#  undef RUBY_SYMBOL_EXPORT_END
#  undef BEGIN_EXTERN_C
#  undef END_EXTERN_C
#  undef EXTERN_C
#endif

#pragma GCC diagnostic pop

#endif // RUBY_WRAPPER_H 