#include <stdint.h>

int mul = 3;
int div = 3;

int main()
{
    int i;
    int sum;

    mul = 6;
    sum = 0;

    // sum = 5050
    for (i = 0; i <= 100; i++)
        sum += i;

    // sum = 3775
    for (i = 0; i <= 50; i++)
        sum -= i;

    // sum = 22650
    sum = sum * mul;

    // sum = 7550
    sum = sum / div;

    if (sum == 7550)
        asm("li t3, 0x01");
    else
        asm("li t3, 0x00");

    int t4;
    asm volatile ("addi t4, %0, 0" :: "r"(sum));

    return 0;
}

