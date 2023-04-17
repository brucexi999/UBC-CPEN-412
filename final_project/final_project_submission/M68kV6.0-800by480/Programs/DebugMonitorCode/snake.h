#ifndef SNAKE_H_
#define SNAKE_H_

#define NUM_VGA_COLUMNS   (80)
#define NUM_VGA_ROWS      (40)
#define BORDER '#'
#define FOOD '@'
#define SNAKE 'S'
#define INITIAL_SNAKE_SPEED (2)
#define INITIAL_SNAKE_LENGTH (3)
#define SNAKE_SPEED_INCREASE (1)
#define SNAKE_LENGTH_LIMIT (2048)
#define MILLISECONDS_PER_SEC (1000)

typedef struct {
    int x;
    int y;
} coord_t;

typedef enum {north, south, west, east} dir_t;


#endif