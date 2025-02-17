#include <stdint.h>

int main() {
    int64_t x = 5;
    int64_t y = x + 20;
    int64_t z = y & 0x3F;
    return z;
}
