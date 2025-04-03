#include "item_queue.h"
#include <stdlib.h>

item_queue *create_item_queue(size_t capacity) {
    item_queue *queue = (item_queue *)malloc(sizeof(item_queue));
    if (!queue) return NULL;

    queue->items = (void **)malloc(capacity * sizeof(void *));
    if (!queue->items) {
        free(queue);
        return NULL;
    }

    if (pthread_mutex_init(&queue->mutex, NULL) != 0) {
        free(queue->items);
        free(queue);
        return NULL;
    }

    queue->capacity = capacity;
    queue->size = 0;
    queue->front = 0;
    queue->rear = 0;

    return queue;
}

void free_item_queue(item_queue *queue) {
    if (queue) {
        pthread_mutex_destroy(&queue->mutex);
        free(queue->items);
        free(queue);
    }
}

bool enqueue_item(item_queue *queue, void *item) {
    if (!queue) return false;

    pthread_mutex_lock(&queue->mutex);
    bool result = false;

    if (queue->size < queue->capacity) {
        queue->items[queue->rear] = item;
        queue->rear = (queue->rear + 1) % queue->capacity;
        queue->size++;
        result = true;
    }

    pthread_mutex_unlock(&queue->mutex);
    return result;
}

void *take_item(item_queue *queue) {
    if (!queue) return NULL;

    pthread_mutex_lock(&queue->mutex);
    void *item = NULL;

    if (queue->size > 0) {
        item = queue->items[queue->front];
        queue->front = (queue->front + 1) % queue->capacity;
        queue->size--;
    }

    pthread_mutex_unlock(&queue->mutex);
    return item;
}

bool is_queue_empty(const item_queue *queue) {
    if (!queue) return true;

    pthread_mutex_lock((pthread_mutex_t *)&queue->mutex);
    bool result = (queue->size == 0);
    pthread_mutex_unlock((pthread_mutex_t *)&queue->mutex);
    return result;
}

bool is_queue_full(const item_queue *queue) {
    if (!queue) return true;

    pthread_mutex_lock((pthread_mutex_t *)&queue->mutex);
    bool result = (queue->size == queue->capacity);
    pthread_mutex_unlock((pthread_mutex_t *)&queue->mutex);
    return result;
} 