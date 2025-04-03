#include <gtest/gtest.h>
#include "ruby_wrapper.h"
#include "wrapped/sequential_filler.h"

// Declare Ruby module and class as external variables
extern VALUE rb_mTypeBalancer;
extern VALUE rb_cSequentialFiller;

class SequentialFillerTest : public ::testing::Test {
protected:
    VALUE create_array(const std::vector<int>& values) {
        VALUE array = rb_ary_new2(values.size());
        rb_gc_register_address(&array);
        for (size_t i = 0; i < values.size(); i++) {
            VALUE item = INT2NUM(values[i]);
            rb_ary_store(array, i, item);
        }
        return array;
    }

    VALUE create_array_with_nils(size_t size) {
        VALUE array = rb_ary_new2(size);
        rb_gc_register_address(&array);
        for (size_t i = 0; i < size; i++) {
            rb_ary_store(array, i, Qnil);
        }
        return array;
    }

    void SetUp() override {
        // Initialize Ruby module and class
        rb_mTypeBalancer = rb_define_module("TypeBalancer");
        rb_cSequentialFiller = rb_define_class_under(rb_mTypeBalancer, "SequentialFiller", rb_cObject);
        
        // Define the methods
        rb_define_singleton_method(rb_cSequentialFiller, "fill", RUBY_METHOD_FUNC(rb_sequential_filler_fill), -1);
        rb_define_method(rb_cSequentialFiller, "initialize", RUBY_METHOD_FUNC(rb_sequential_filler_initialize), -1);
        rb_define_alloc_func(rb_cSequentialFiller, sequential_filler_alloc);
        rb_define_method(rb_cSequentialFiller, "fill_gaps", RUBY_METHOD_FUNC(rb_sequential_filler_fill_gaps), -1);
        rb_define_method(rb_cSequentialFiller, "find_next_item", RUBY_METHOD_FUNC(find_next_item), 0);
        
        // Initialize instance variables
        items_arrays = rb_ary_new();
        rb_gc_register_address(&items_arrays);
    }

    void TearDown() override {
        rb_gc_unregister_address(&items_arrays);
    }

    VALUE items_arrays;
};

TEST_F(SequentialFillerTest, CreateFillerWithEmptyArrays) {
    sequential_filler_context *filler = create_sequential_filler_context(items_arrays);
    
    ASSERT_NE(nullptr, filler);
    EXPECT_EQ(0, filler->queue_count);
    EXPECT_EQ(nullptr, filler->queues);
    
    free_sequential_filler_context(filler);
}

TEST_F(SequentialFillerTest, CreateFillerWithValidArrays) {
    VALUE array1 = create_array({1, 2});
    VALUE array2 = create_array({3, 4});
    rb_gc_register_address(&array1);
    rb_gc_register_address(&array2);
    
    rb_ary_push(items_arrays, array1);
    rb_ary_push(items_arrays, array2);
    
    sequential_filler_context *filler = create_sequential_filler_context(items_arrays);
    
    ASSERT_NE(nullptr, filler);
    EXPECT_EQ(2, filler->queue_count);
    EXPECT_NE(nullptr, filler->queues);
    
    free_sequential_filler_context(filler);
    
    rb_gc_unregister_address(&array2);
    rb_gc_unregister_address(&array1);
}

TEST_F(SequentialFillerTest, CreateFillerWithInvalidInput) {
    // Create a string instead of an array
    VALUE invalid_item = rb_str_new_cstr("Not an array");
    rb_gc_register_address(&invalid_item);
    rb_ary_push(items_arrays, invalid_item);
    
    int state = 0;
    VALUE result = rb_protect([](VALUE data) -> VALUE {
        VALUE items_arrays = (VALUE)data;
        sequential_filler_context* filler = create_sequential_filler_context(items_arrays);
        return filler ? (VALUE)filler : Qnil;
    }, (VALUE)items_arrays, &state);
    
    EXPECT_NE(0, state); // Expect an exception to be raised
    EXPECT_EQ(Qnil, result);
    
    rb_gc_unregister_address(&invalid_item);
}

TEST_F(SequentialFillerTest, CreateFillerWithMaxArrays) {
    const size_t max_arrays = 1000;
    std::vector<VALUE> arrays;
    
    for (size_t i = 0; i < max_arrays; i++) {
        VALUE array = create_array({(int)i});
        arrays.push_back(array);
        rb_gc_register_address(&arrays.back());
        rb_ary_push(items_arrays, array);
    }
    
    sequential_filler_context *filler = create_sequential_filler_context(items_arrays);
    
    ASSERT_NE(nullptr, filler);
    EXPECT_EQ(max_arrays, filler->queue_count);
    EXPECT_NE(nullptr, filler->queues);
    
    free_sequential_filler_context(filler);
    
    for (VALUE array : arrays) {
        rb_gc_unregister_address(&array);
    }
}

TEST_F(SequentialFillerTest, FindNextItemSequentially) {
    // Create arrays and register them with GC
    VALUE array1 = create_array({1, 2});
    VALUE array2 = create_array({3, 4});
    
    // Push arrays into items_arrays
    rb_ary_push(items_arrays, array1);
    rb_ary_push(items_arrays, array2);
    
    // Create collection array
    VALUE collection = create_array_with_nils(4);
    
    // Create filler instance with proper error handling
    int state = 0;
    VALUE args[] = {collection, items_arrays};
    VALUE filler = rb_protect([](VALUE data) -> VALUE {
        VALUE* args = (VALUE*)data;
        return rb_class_new_instance(2, args, rb_cSequentialFiller);
    }, (VALUE)args, &state);
    
    ASSERT_EQ(0, state) << "Failed to create filler instance";
    ASSERT_NE(Qnil, filler) << "Filler instance is nil";
    
    rb_gc_register_address(&filler);
    
    // Test sequential retrieval with proper error handling
    VALUE items[4];
    int expected_values[] = {1, 3, 2, 4};
    
    for (int i = 0; i < 4; i++) {
        state = 0;
        items[i] = rb_protect([](VALUE data) -> VALUE {
            return rb_funcall(data, rb_intern("find_next_item"), 0);
        }, filler, &state);
        
        ASSERT_EQ(0, state) << "Error calling find_next_item";
        ASSERT_NE(Qnil, items[i]) << "Item " << i << " is nil";
        EXPECT_EQ(expected_values[i], NUM2INT(items[i])) << "Unexpected value at index " << i;
        
        // Register each item with GC to prevent premature collection
        rb_gc_register_address(&items[i]);
    }
    
    // Test that we've exhausted all items
    state = 0;
    VALUE final_item = rb_protect([](VALUE data) -> VALUE {
        return rb_funcall(data, rb_intern("find_next_item"), 0);
    }, filler, &state);
    
    ASSERT_EQ(0, state) << "Error calling find_next_item for final check";
    EXPECT_EQ(Qnil, final_item) << "Expected nil after all items consumed";
    
    // Unregister all items from GC in reverse order
    for (int i = 3; i >= 0; i--) {
        rb_gc_unregister_address(&items[i]);
    }
    
    // Unregister filler and arrays
    rb_gc_unregister_address(&filler);
}

TEST_F(SequentialFillerTest, FindNextItemWithInsufficientItems) {
    VALUE array1 = create_array({1});
    VALUE array2 = create_array({2});
    rb_gc_register_address(&array1);
    rb_gc_register_address(&array2);
    
    rb_ary_push(items_arrays, array1);
    rb_ary_push(items_arrays, array2);
    
    VALUE collection = rb_ary_new();
    rb_gc_register_address(&collection);
    
    VALUE args[2] = {collection, items_arrays};
    VALUE filler = rb_class_new_instance(2, args, rb_cSequentialFiller);
    rb_gc_register_address(&filler);
    
    // Test retrieval with insufficient items
    VALUE item;
    item = rb_funcall(filler, rb_intern("find_next_item"), 0);
    ASSERT_NE(Qnil, item);
    EXPECT_EQ(1, NUM2INT(item));
    
    item = rb_funcall(filler, rb_intern("find_next_item"), 0);
    ASSERT_NE(Qnil, item);
    EXPECT_EQ(2, NUM2INT(item));
    
    EXPECT_EQ(Qnil, rb_funcall(filler, rb_intern("find_next_item"), 0));
    
    rb_gc_unregister_address(&filler);
    rb_gc_unregister_address(&collection);
    rb_gc_unregister_address(&array2);
    rb_gc_unregister_address(&array1);
}

TEST_F(SequentialFillerTest, FindNextItemWithEmptyQueues) {
    VALUE array1 = create_array({});
    rb_gc_register_address(&array1);
    rb_ary_push(items_arrays, array1);
    
    VALUE collection = rb_ary_new();
    rb_gc_register_address(&collection);
    
    VALUE args[2] = {collection, items_arrays};
    VALUE filler = rb_class_new_instance(2, args, rb_cSequentialFiller);
    rb_gc_register_address(&filler);
    
    // Test retrieval with empty queues
    EXPECT_EQ(Qnil, rb_funcall(filler, rb_intern("find_next_item"), 0));
    
    rb_gc_unregister_address(&filler);
    rb_gc_unregister_address(&collection);
    rb_gc_unregister_address(&array1);
}

TEST_F(SequentialFillerTest, FindNextItemWithThreadSafety) {
    VALUE array1 = create_array({1, 2, 3, 4, 5});
    rb_gc_register_address(&array1);
    rb_ary_push(items_arrays, array1);
    
    VALUE collection = rb_ary_new();
    rb_gc_register_address(&collection);
    
    VALUE args[2] = {collection, items_arrays};
    VALUE filler = rb_class_new_instance(2, args, rb_cSequentialFiller);
    rb_gc_register_address(&filler);
    
    // Run multiple retrievals in parallel
    #pragma omp parallel for
    for (int i = 0; i < 10; i++) {
        VALUE item = rb_funcall(filler, rb_intern("find_next_item"), 0);
        if (item != Qnil) {
            int value = NUM2INT(item);
            EXPECT_GE(value, 1);
            EXPECT_LE(value, 5);
        }
    }
    
    rb_gc_unregister_address(&filler);
    rb_gc_unregister_address(&collection);
    rb_gc_unregister_address(&array1);
} 