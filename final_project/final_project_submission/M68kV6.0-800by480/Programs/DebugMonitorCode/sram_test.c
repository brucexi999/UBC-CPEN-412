#include <stdio.h>
#define addr1_value   *(volatile unsigned char *)(0x08020000)

int main (void) {
    addr1_value = 0x55;
    printf ("%c", addr1_value);
    return 0;
}

