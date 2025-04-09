#include "sequential_filler.h"
#include <ruby.h>
#include <ruby/intern.h>

VALUE rb_cSequentialFiller;

static void sequential_filler_mark(void *ptr) {
    sequential_filler_context *context = (sequential_filler_context *)ptr;
    if (context) {
        rb_gc_mark(context->result);
        rb_gc_mark(context->collection);
    }
}

static void sequential_filler_free(void *ptr) {
    if (ptr) {
        xfree(ptr);
    }
}

static size_t sequential_filler_memsize(const void *ptr) {
    (void)ptr;  // Explicitly ignore the parameter
    return sizeof(sequential_filler_context);
}

static const rb_data_type_t sequential_filler_type = {
    "SequentialFiller",
    {
        sequential_filler_mark,
        sequential_filler_free,
        sequential_filler_memsize,
        0, /* dcompact */
    },
    0, 0, /* parent, data */
    RUBY_TYPED_FREE_IMMEDIATELY
};

static VALUE sequential_filler_alloc(VALUE klass) {
    sequential_filler_context *context;
    VALUE obj = TypedData_Make_Struct(klass, sequential_filler_context, &sequential_filler_type, context);
    context->result = Qnil;
    context->collection = Qnil;
    context->current_position = 0;
    context->total_positions = 0;
    return obj;
}

static VALUE find_next_item(VALUE self) {
    sequential_filler_context *context;
    TypedData_Get_Struct(self, sequential_filler_context, &sequential_filler_type, context);
    
    if (context->current_position >= context->total_positions) {
        return Qnil;
    }
    
    VALUE item = rb_ary_entry(context->collection, context->current_position);
    context->current_position++;
    return item;
}

void fill_gaps_sequential_context(sequential_filler_context *filler, const long *positions, size_t position_count) {
    if (!filler || !positions || position_count == 0) {
        return;
    }

    filler->result = rb_ary_new_capa(position_count);
    filler->total_positions = position_count;
    filler->current_position = 0;

    for (size_t i = 0; i < position_count; i++) {
        VALUE item = find_next_item(filler->result);
        rb_ary_store(filler->result, positions[i], item);
    }
}

static VALUE rb_sequential_filler_initialize(VALUE self, VALUE collection) {
    sequential_filler_context *context;
    TypedData_Get_Struct(self, sequential_filler_context, &sequential_filler_type, context);
    
    Check_Type(collection, T_ARRAY);
    context->collection = collection;
    context->current_position = 0;
    context->total_positions = RARRAY_LEN(collection);
    
    return self;
}

static VALUE rb_sequential_filler_fill_gaps(VALUE self, VALUE positions) {
    sequential_filler_context *context;
    TypedData_Get_Struct(self, sequential_filler_context, &sequential_filler_type, context);
    
    Check_Type(positions, T_ARRAY);
    const VALUE *pos_array = RARRAY_CONST_PTR(positions);
    size_t pos_count = RARRAY_LEN(positions);
    
    // Convert Ruby array of positions to C array
    long *c_positions = ALLOCA_N(long, pos_count);
    for (size_t i = 0; i < pos_count; i++) {
        c_positions[i] = NUM2LONG(pos_array[i]);
    }
    
    fill_gaps_sequential_context(context, c_positions, pos_count);
    return context->result;
}

void Init_sequential_filler(VALUE mTypeBalancer) {
    rb_cSequentialFiller = rb_define_class_under(mTypeBalancer, "SequentialFiller", rb_cObject);
    rb_define_alloc_func(rb_cSequentialFiller, sequential_filler_alloc);
    rb_define_method(rb_cSequentialFiller, "initialize", rb_sequential_filler_initialize, 1);
    rb_define_method(rb_cSequentialFiller, "fill_gaps", rb_sequential_filler_fill_gaps, 1);
} 


