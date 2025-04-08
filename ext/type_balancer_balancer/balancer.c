#include <ruby.h>
#include "balancer.h"

typedef struct {
    VALUE collection;
    VALUE type_field;
    VALUE types;
    long total_count;
} BalancerState;

static VALUE get_item_type(VALUE item, VALUE type_field) {
    // Fast path: try hash access first
    if (RB_TYPE_P(item, T_HASH)) {
        VALUE type = rb_hash_aref(item, type_field);
        if (type != Qnil) return type;
        
        // Try string key if symbol didn't work
        if (RB_TYPE_P(type_field, T_SYMBOL)) {
            VALUE str_key = rb_sym_to_s(type_field);
            type = rb_hash_aref(item, str_key);
            if (type != Qnil) return type;
        }
    }
    
    // Slower path: try method call
    if (rb_respond_to(item, rb_to_id(type_field))) {
        return rb_funcall(item, rb_to_id(type_field), 0);
    }
    
    rb_raise(rb_eArgError, "Cannot access type field on item");
}

static VALUE group_items_by_type(BalancerState* state) {
    VALUE items_by_type = rb_ary_new_capa(RARRAY_LEN(state->types));
    rb_gc_register_address(&items_by_type);
    
    // Pre-allocate arrays for each type
    for (long i = 0; i < RARRAY_LEN(state->types); i++) {
        rb_ary_push(items_by_type, rb_ary_new());
    }
    
    // Single pass through collection to group items
    VALUE* collection_ptr = RARRAY_PTR(state->collection);
    for (long i = 0; i < state->total_count; i++) {
        VALUE item = collection_ptr[i];
        VALUE item_type = get_item_type(item, state->type_field);
        
        // Find type index
        for (long j = 0; j < RARRAY_LEN(state->types); j++) {
            if (rb_equal(item_type, RARRAY_AREF(state->types, j))) {
                rb_ary_push(RARRAY_AREF(items_by_type, j), item);
                break;
            }
        }
    }
    
    rb_gc_unregister_address(&items_by_type);
    return items_by_type;
}

static VALUE rb_balancer_initialize(VALUE self, VALUE collection, VALUE type_field, VALUE types) {
    BalancerState* state;
    Data_Get_Struct(self, BalancerState, state);
    
    // Store input parameters
    state->collection = collection;
    state->type_field = type_field;
    state->types = types;
    state->total_count = RARRAY_LEN(collection);
    
    return self;
}

static VALUE rb_balancer_balance(VALUE self) {
    BalancerState* state;
    Data_Get_Struct(self, BalancerState, state);
    
    // Early returns
    if (state->total_count == 0) return rb_ary_new();
    
    // Group items by type efficiently
    VALUE items_by_type = group_items_by_type(state);
    rb_gc_register_address(&items_by_type);
    
    // Calculate target positions for each type
    VALUE target_positions = rb_ary_new_capa(RARRAY_LEN(state->types));
    rb_gc_register_address(&target_positions);
    
    for (long i = 0; i < RARRAY_LEN(state->types); i++) {
        VALUE items = RARRAY_AREF(items_by_type, i);
        double ratio = (RARRAY_LEN(state->types) == 1) ? 1.0 :
                      (i == 0) ? 0.35 : 0.25;
                      
        VALUE mTypeBalancer = rb_const_get(rb_cObject, rb_intern("TypeBalancer"));
        VALUE cDistributor = rb_const_get(mTypeBalancer, rb_intern("Distributor"));
        VALUE positions = rb_funcall(cDistributor, rb_intern("calculate_target_positions"), 3,
                                   LONG2NUM(state->total_count),
                                   LONG2NUM(RARRAY_LEN(items)),
                                   DBL2NUM(ratio));
        rb_ary_push(target_positions, positions);
    }
    
    // Create result array
    VALUE result = rb_ary_new_capa(state->total_count);
    rb_gc_register_address(&result);
    
    // Fill result array with nil
    for (long i = 0; i < state->total_count; i++) {
        rb_ary_store(result, i, Qnil);
    }
    
    // Place items at their positions
    for (long type_idx = 0; type_idx < RARRAY_LEN(state->types); type_idx++) {
        VALUE items = RARRAY_AREF(items_by_type, type_idx);
        VALUE positions = RARRAY_AREF(target_positions, type_idx);
        
        long pos_len = RARRAY_LEN(positions);
        for (long i = 0; i < pos_len && i < RARRAY_LEN(items); i++) {
            long pos = NUM2LONG(RARRAY_AREF(positions, i));
            rb_ary_store(result, pos, RARRAY_AREF(items, i));
        }
    }
    
    // Clean up
    rb_gc_unregister_address(&result);
    rb_gc_unregister_address(&target_positions);
    rb_gc_unregister_address(&items_by_type);
    
    return result;
}

static void balancer_mark(void* ptr) {
    BalancerState* state = (BalancerState*)ptr;
    if (state) {
        rb_gc_mark(state->collection);
        rb_gc_mark(state->type_field);
        rb_gc_mark(state->types);
    }
}

static void balancer_free(void* ptr) {
    xfree(ptr);
}

static VALUE rb_balancer_alloc(VALUE klass) {
    BalancerState* state = ALLOC(BalancerState);
    MEMZERO(state, BalancerState, 1);
    return Data_Wrap_Struct(klass, balancer_mark, balancer_free, state);
}

// Initialize the extension
void Init_balancer(void) {
    VALUE mTypeBalancer = rb_define_module("TypeBalancer");
    VALUE cBalancer = rb_define_class_under(mTypeBalancer, "CBalancer", rb_cObject);
    
    rb_define_alloc_func(cBalancer, rb_balancer_alloc);
    rb_define_method(cBalancer, "initialize", rb_balancer_initialize, 3);
    rb_define_method(cBalancer, "balance", rb_balancer_balance, 0);
} 