#include "alternating_filler.h"
#include "item_queue.h"
#include <ruby.h>
#include <ruby/intern.h>  // For TypedData_* macros
#include <ruby/ruby.h>    // For rb_* functions and macros
#include <stdlib.h>       // For malloc
#include <stdint.h>       // For uintptr_t

// Declare the Ruby module
extern VALUE rb_mTypeBalancer;
static VALUE rb_cAlternatingFiller;

static void mark_alternating_filler_context(void *ptr) {
    alternating_filler_context *context = (alternating_filler_context *)ptr;
    if (context && !NIL_P(context->result_ptr)) {
        rb_gc_mark(context->result_ptr);
    }
}

static void free_alternating_filler_data(void *ptr) {
    alternating_filler_context *context = (alternating_filler_context *)ptr;
    if (context) {
        if (context->primary_items) {
            free_item_queue(context->primary_items);
        }
        if (context->secondary_items) {
            free_item_queue(context->secondary_items);
        }
        free(context);
    }
}

static size_t alternating_filler_size(const void *ptr) {
    (void)ptr;
    return sizeof(alternating_filler_context);
}

static const rb_data_type_t rb_alternating_filler_type = {
    .wrap_struct_name = "AlternatingFiller",
    .function = {
        .dmark = mark_alternating_filler_context,
        .dfree = free_alternating_filler_data,
        .dsize = alternating_filler_size,
    },
    .data = NULL,
    .flags = RUBY_TYPED_FREE_IMMEDIATELY
};

alternating_filler_context *create_alternating_filler_context(
    item_queue *first_priority_items,
    item_queue *second_priority_items
) {
    alternating_filler_context *context = malloc(sizeof(alternating_filler_context));
    if (!context) {
        return NULL;
    }
    
    context->primary_items = first_priority_items;
    context->secondary_items = second_priority_items;
    context->result_ptr = Qnil;
    context->result_size = 0;
    
    return context;
}

void free_alternating_filler_context(alternating_filler_context *filler) {
    if (filler) {
        if (filler->primary_items) {
            free_item_queue(filler->primary_items);
        }
        if (filler->secondary_items) {
            free_item_queue(filler->secondary_items);
        }
        free(filler);
    }
}

static VALUE rb_alternating_filler_new(VALUE self, VALUE items_array) {
    (void)self; // Suppress unused parameter warning
    Check_Type(items_array, T_ARRAY);
    
    long total_items = RARRAY_LEN(items_array);
    long half_items = total_items / 2;
    
    item_queue *primary_items = create_item_queue(half_items + (total_items % 2));
    item_queue *secondary_items = create_item_queue(half_items);
    
    if (!primary_items || !secondary_items) {
        if (primary_items) {
            free_item_queue(primary_items);
        }
        if (secondary_items) {
            free_item_queue(secondary_items);
        }
        rb_raise(rb_eNoMemError, "Failed to allocate item queues");
    }
    
    // Split items between queues
    for (long i = 0; i < total_items; i++) {
        VALUE item = rb_ary_entry(items_array, i);
        if (i % 2 == 0) {
            // Cast VALUE to void* is safe in Ruby's implementation
            enqueue_item(primary_items, (void *)(uintptr_t)item);
        } else {
            enqueue_item(secondary_items, (void *)(uintptr_t)item);
        }
    }
    
    alternating_filler_context *context = create_alternating_filler_context(primary_items, secondary_items);
    if (!context) {
        free_item_queue(primary_items);
        free_item_queue(secondary_items);
        rb_raise(rb_eNoMemError, "Failed to allocate alternating filler context");
    }
    
    return TypedData_Wrap_Struct(rb_cAlternatingFiller, &rb_alternating_filler_type, context);
}

static VALUE find_next_item(VALUE self) {
    alternating_filler_context *context = NULL;
    TypedData_Get_Struct(self, alternating_filler_context, &rb_alternating_filler_type, context);
    
    void *item = NULL;
    item = take_item(context->primary_items);
    if (!item) {
        item = take_item(context->secondary_items);
    }
    
    return item ? (VALUE)(uintptr_t)item : Qnil;
}

void fill_gaps_alternating_context(alternating_filler_context *filler, const long *positions, size_t position_count) {
    if (!filler || !positions || !filler->result_ptr || position_count == 0) {
        return;
    }

    VALUE *result_ptr = RARRAY_PTR(filler->result_ptr);
    for (size_t i = 0; i < position_count; i++) {
        long pos = positions[i];
        if (pos < 0 || (size_t)pos >= filler->result_size) {
            continue;
        }

        // Only fill if current value is nil
        if (result_ptr[pos] == Qnil) {
            VALUE next_item = find_next_item(Qnil);  // We don't use self here
            if (next_item != Qnil) {
                result_ptr[pos] = next_item;
            }
        }
    }
}

void Init_alternating_filler(void) {
    rb_cAlternatingFiller = rb_define_class_under(rb_mTypeBalancer, "AlternatingFiller", rb_cObject);
    rb_define_singleton_method(rb_cAlternatingFiller, "new", rb_alternating_filler_new, 1);
    rb_define_method(rb_cAlternatingFiller, "find_next_item", find_next_item, 0);
}
