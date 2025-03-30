#include "sequential_filler.h"
#include <stdlib.h>
#include <time.h>
#include <ruby.h>
#include <ruby/thread.h>

VALUE rb_cSequentialFiller;

static double get_time() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec * 1e-9;
}

VALUE find_next_item(VALUE self) {
    sequential_filler_context* context;
    TypedData_Get_Struct(self, sequential_filler_context, &sequential_filler_type, context);
    
    if (!context || !context->queues || context->queue_count == 0) {
        return Qnil;
    }
    
    void *item = NULL;
    size_t original_queue = context->current_queue;
    VALUE result = Qnil;
    
    do {
        item_queue *queue = context->queues[context->current_queue];
        if (queue) {
            item = take_item(queue);  // This already handles empty check with mutex
            if (item) {
                VALUE ruby_item = (VALUE)item;
                // Check if the item is a valid Ruby object and hasn't been GC'd
                if (ruby_item && !NIL_P(ruby_item) && RTEST(ruby_item) && RB_TYPE_P(ruby_item, T_FIXNUM)) {
                    // Create a copy of the item to ensure it persists
                    result = rb_obj_dup(ruby_item);
                    // Register the result with the GC to prevent it from being collected
                    rb_gc_register_address(&result);
                    break;
                }
            }
        }
        // Move to next queue if current one is empty or had invalid item
        context->current_queue = (context->current_queue + 1) % context->queue_count;
    } while (context->current_queue != original_queue);
    
    // Move to next queue for next time if we found an item
    if (result != Qnil) {
        context->current_queue = (context->current_queue + 1) % context->queue_count;
        // Unregister the result from GC since we're returning it
        rb_gc_unregister_address(&result);
    }
    
    return result;
}

sequential_filler_context* create_sequential_filler_context(VALUE items_arrays) {
    Check_Type(items_arrays, T_ARRAY);
    
    sequential_filler_context* context = ALLOC(sequential_filler_context);
    if (!context) {
        rb_raise(rb_eNoMemError, "Failed to allocate sequential_filler_context");
        return NULL;
    }
    
    // Initialize all fields to safe values
    context->queues = NULL;
    context->queue_count = 0;
    context->current_queue = 0;
    context->source_arrays = Qnil;
    context->result_ptr = NULL;
    context->result_size = 0;
    
    long array_count = RARRAY_LEN(items_arrays);
    if (array_count == 0) {
        return context;
    }
    
    // Allocate array of queue pointers
    context->queues = ALLOC_N(item_queue*, array_count);
    if (!context->queues) {
        ruby_xfree(context);
        rb_raise(rb_eNoMemError, "Failed to allocate queues array");
        return NULL;
    }
    
    context->queue_count = array_count;
    
    // Initialize each queue and fill it with items
    for (long i = 0; i < array_count; i++) {
        VALUE items = rb_ary_entry(items_arrays, i);
        Check_Type(items, T_ARRAY);
        
        long items_count = RARRAY_LEN(items);
        // Create queue with capacity for all items
        context->queues[i] = create_item_queue(items_count > 0 ? items_count : 1);
        if (!context->queues[i]) {
            // Clean up previously allocated queues
            for (long j = 0; j < i; j++) {
                free_item_queue(context->queues[j]);
            }
            ruby_xfree(context->queues);
            ruby_xfree(context);
            rb_raise(rb_eNoMemError, "Failed to create item queue");
            return NULL;
        }
        
        // Fill the queue with items
        for (long j = 0; j < items_count; j++) {
            VALUE item = rb_ary_entry(items, j);
            // Only enqueue valid Ruby objects
            if (!NIL_P(item) && RB_TYPE_P(item, T_FIXNUM)) {
                // Create a copy of the item and register it with the GC
                VALUE item_copy = rb_obj_dup(item);
                rb_gc_register_address(&item_copy);
                if (!enqueue_item(context->queues[i], (void*)item_copy)) {
                    // Clean up on failure
                    rb_gc_unregister_address(&item_copy);
                    for (long k = 0; k < i; k++) {
                        free_item_queue(context->queues[k]);
                    }
                    free_item_queue(context->queues[i]);
                    ruby_xfree(context->queues);
                    ruby_xfree(context);
                    rb_raise(rb_eRuntimeError, "Failed to enqueue item");
                    return NULL;
                }
            }
        }
    }
    
    // Store a copy of the source arrays and register it with the GC
    context->source_arrays = rb_obj_dup(items_arrays);
    rb_gc_register_address(&context->source_arrays);
    
    return context;
}

void free_sequential_filler_context(sequential_filler_context* context) {
    if (!context) return;
    
    // Unregister source_arrays from GC if it exists
    if (context->source_arrays != Qnil) {
        rb_gc_unregister_address(&context->source_arrays);
    }
    
    // Free queues and their contents
    if (context->queues) {
        for (size_t i = 0; i < context->queue_count; i++) {
            item_queue* queue = context->queues[i];
            if (queue) {
                // Unregister all items in the queue from GC
                while (!is_queue_empty(queue)) {
                    void* item = take_item(queue);
                    if (item) {
                        VALUE ruby_item = (VALUE)item;
                        if (ruby_item && !NIL_P(ruby_item)) {
                            rb_gc_unregister_address(&ruby_item);
                        }
                    }
                }
                free_item_queue(queue);
            }
        }
        ruby_xfree(context->queues);
    }
    
    ruby_xfree(context);
}

VALUE fill_gaps_sequential_context(VALUE self, VALUE collection, VALUE positions, sequential_filler_context* filler) {
    double start_time = get_time();
    Check_Type(collection, T_ARRAY);
    Check_Type(positions, T_ARRAY);
    
    if (!filler) {
        rb_raise(rb_eArgError, "Filler context is NULL");
    }
    
    long pos_len = RARRAY_LEN(positions);
    if (pos_len == 0) return collection;
    
    // Create a new array to store the result
    VALUE result = rb_ary_dup(collection);
    rb_gc_register_address(&result);
    
    // Store the result array's data for direct access
    filler->result_ptr = RARRAY_PTR(result);
    filler->result_size = RARRAY_LEN(result);
    
    for (long i = 0; i < pos_len; i++) {
        VALUE pos_val = rb_ary_entry(positions, i);
        if (!RB_TYPE_P(pos_val, T_FIXNUM)) continue;
        
        long pos = NUM2LONG(pos_val);
        if (pos < 0 || (size_t)pos >= filler->result_size) continue;
        
        // Only fill if current value is nil
        if (NIL_P(rb_ary_entry(result, pos))) {
            VALUE next_item = find_next_item(self);
            if (!NIL_P(next_item) && RB_TYPE_P(next_item, T_FIXNUM)) {
                rb_ary_store(result, pos, next_item);
            }
        }
    }
    
    // Clean up
    filler->result_ptr = NULL;
    filler->result_size = 0;
    
    // Calculate and log the time taken
    double end_time = get_time();
    fprintf(stderr, "fill_gaps_sequential_context took %f seconds\n", end_time - start_time);
    
    // Unregister the result from GC since we're returning it
    rb_gc_unregister_address(&result);
    return result;
}

VALUE rb_sequential_filler_initialize(int argc, VALUE* argv, VALUE self) {
    if (argc != 2) {
        rb_raise(rb_eArgError, "wrong number of arguments (given %d, expected 2)", argc);
    }
    
    VALUE collection = argv[0];
    VALUE items_arrays = argv[1];
    
    Check_Type(collection, T_ARRAY);
    Check_Type(items_arrays, T_ARRAY);
    
    // Store collection and items_arrays in instance variables
    rb_iv_set(self, "@collection", collection);
    rb_iv_set(self, "@items_arrays", items_arrays);
    
    // Get the existing context from the object
    sequential_filler_context* context;
    TypedData_Get_Struct(self, sequential_filler_context, &sequential_filler_type, context);
    
    // Create a new filler context
    sequential_filler_context* new_context = create_sequential_filler_context(items_arrays);
    if (!new_context) {
        rb_raise(rb_eRuntimeError, "Failed to create sequential filler context");
        return Qnil;
    }
    
    // Copy data from new context to existing context
    context->queues = new_context->queues;
    context->queue_count = new_context->queue_count;
    context->current_queue = new_context->current_queue;
    context->source_arrays = new_context->source_arrays;
    context->result_ptr = new_context->result_ptr;
    context->result_size = new_context->result_size;
    
    // Clear pointers in new_context to prevent double-free
    new_context->queues = NULL;
    new_context->source_arrays = Qnil;
    ruby_xfree(new_context);
    
    return self;
}

static void free_sequential_filler_data(void* ptr) {
    if (!ptr) return;
    free_sequential_filler_context((sequential_filler_context*)ptr);
}

static size_t sequential_filler_size(const void* ptr) {
    if (!ptr) return 0;
    const sequential_filler_context* context = (const sequential_filler_context*)ptr;
    return sizeof(*context);
}

const rb_data_type_t sequential_filler_type = {
    .wrap_struct_name = "sequential_filler",
    .function = {
        .dmark = NULL,
        .dfree = free_sequential_filler_data,
        .dsize = sequential_filler_size,
    },
    .data = NULL,
    .flags = RUBY_TYPED_FREE_IMMEDIATELY | RUBY_TYPED_WB_PROTECTED
};

VALUE sequential_filler_alloc(VALUE klass) {
    sequential_filler_context *context = ALLOC(sequential_filler_context);
    if (!context) rb_raise(rb_eNoMemError, "Failed to allocate sequential filler context");
    
    context->queues = NULL;
    context->queue_count = 0;
    context->current_queue = 0;
    context->source_arrays = Qnil;
    context->result_ptr = NULL;
    context->result_size = 0;
    
    return TypedData_Wrap_Struct(klass, &sequential_filler_type, context);
}

VALUE rb_sequential_filler_fill_gaps(int argc, VALUE* argv, VALUE self) {
    if (argc != 1) {
        rb_raise(rb_eArgError, "wrong number of arguments (given %d, expected 1)", argc);
    }
    
    VALUE positions = argv[0];
    sequential_filler_context* context;
    TypedData_Get_Struct(self, sequential_filler_context, &sequential_filler_type, context);
    VALUE collection = rb_iv_get(self, "@collection");
    return fill_gaps_sequential_context(self, collection, positions, context);
}

VALUE rb_sequential_filler_fill(int argc, VALUE* argv, VALUE klass) {
    if (argc != 3) {
        rb_raise(rb_eArgError, "wrong number of arguments (given %d, expected 3)", argc);
    }
    
    VALUE collection = argv[0];
    VALUE positions = argv[1];
    VALUE items_arrays = argv[2];
    
    Check_Type(collection, T_ARRAY);
    Check_Type(positions, T_ARRAY);
    Check_Type(items_arrays, T_ARRAY);
    
    sequential_filler_context* context = create_sequential_filler_context(items_arrays);
    if (!context) {
        rb_raise(rb_eArgError, "Failed to create sequential filler");
    }
    
    VALUE result = fill_gaps_sequential_context(klass, collection, positions, context);
    free_sequential_filler_context(context);
    return result;
}

void Init_sequential_filler(VALUE mTypeBalancer) {
    VALUE cSequentialFiller = rb_define_class_under(mTypeBalancer, "SequentialFiller", rb_cObject);
    rb_define_singleton_method(cSequentialFiller, "fill", RUBY_METHOD_FUNC(rb_sequential_filler_fill), -1);
    rb_define_method(cSequentialFiller, "initialize", RUBY_METHOD_FUNC(rb_sequential_filler_initialize), -1);
    rb_define_alloc_func(cSequentialFiller, sequential_filler_alloc);
    rb_define_method(cSequentialFiller, "fill_gaps", RUBY_METHOD_FUNC(rb_sequential_filler_fill_gaps), -1);
    rb_define_method(cSequentialFiller, "find_next_item", RUBY_METHOD_FUNC(find_next_item), 0);
    rb_cSequentialFiller = cSequentialFiller;
} 


