#include <stdint.h>
#include <stdio.h>

int main() {
    int64_t x = 5;
    int64_t y = x + 20;
    int64_t z = y & 0x3F;
    printf("Result: %ld\n", z);
    return 0;
}
