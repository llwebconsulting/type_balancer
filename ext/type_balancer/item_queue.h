#ifndef USERS_ANON_GEMS_TYPE_BALANCER_EXT_TYPE_BALANCER_ITEM_QUEUE_H
#define USERS_ANON_GEMS_TYPE_BALANCER_EXT_TYPE_BALANCER_ITEM_QUEUE_H

#include <pthread.h>
#include <stdbool.h>
#include <stddef.h>

// Structure to manage a queue of items
typedef struct {
    void **items;
    size_t capacity;
    size_t size;
    size_t front;
    size_t rear;
    pthread_mutex_t mutex;
} item_queue;

// Create a new item queue
item_queue *create_item_queue(size_t capacity);

// Free resources associated with an item queue
void free_item_queue(item_queue *queue);

// Check if the queue is empty
bool is_queue_empty(const item_queue *queue);

// Check if the queue is full
bool is_queue_full(const item_queue *queue);

// Add an item to the queue
bool enqueue_item(item_queue *queue, void *item);

// Take the next item from the queue
void *take_item(item_queue *queue);

#endif /* USERS_ANON_GEMS_TYPE_BALANCER_EXT_TYPE_BALANCER_ITEM_QUEUE_H */ 
