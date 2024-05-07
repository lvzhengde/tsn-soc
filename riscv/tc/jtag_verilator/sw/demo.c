#include <stdint.h>

#define CSR_SIM_CTRL       0x8b2
#define CSR_SIM_CTRL_PUTC (1 << 24)

void sim_print(const char *str) 
{
#ifdef SIMULATION
    int x;
    while (*str != '\0') {
        x = (*str) & 0xff;
        x = x | CSR_SIM_CTRL_PUTC;
        //asm volatile ("csrw dscratch, %0" :: "r"(x));
        asm volatile ("csrw %0, %1" : : "i"(CSR_SIM_CTRL), "r"(x));

        str++;
    }

    x = '\n' & 0xff;
    x = x | CSR_SIM_CTRL_PUTC;
    //asm volatile ("csrw dscratch, %0" :: "r"(x));
    asm volatile ("csrw %0, %1" : : "i"(CSR_SIM_CTRL), "r"(x));
#endif
}

char int2asc(int i)
{
    char c;
    int j = i % 10;

    switch (j) {
        case 0: 
            c = '0';
            break;
        case 1:
            c = '1';
            break;
        case 2:
            c = '2';
            break;
        case 3:
            c = '3';
            break;
        case 4:
            c = '4';
            break;
        case 5:
            c = '5';
            break;
        case 6:
            c = '6';
            break;
        case 7:
            c = '7';
            break;
        case 8:
            c = '8';
            break;
        case 9:
            c = '9';
            break;
        default:
            c = 'x';
    }

    return c;
}

int g_mul = 3;
int g_div = 3;

int main()
{
    int i;
    int sum;
    int count;
    char disp[] = {'i', ' ', '=', ' ', 0, 0};

    sim_print("After reset, enter main program!");
    count = 0;

    for (;;) {
        g_mul = 6;
        sum = 0;

        // sum = 5050
        for (i = 0; i <= 100; i++)
            sum += i;

        // sum = 3775
        for (i = 0; i <= 50; i++)
            sum -= i;

        // sum = 22650
        sum = sum * g_mul;

        // sum = 7550, i.e 0x1d7e
        sum = sum / g_div;

        int t4;

        //t4 = 0x1d7
        t4 = sum >> 4;

        //t4 = 0x1d70
        t4 = t4 << 4;

        //t4 = 0x1d73
        t4 = t4 | 0x3;

        //t4 = 0xd50, i.e. 3408
        t4 = t4 & 0xfd0;

        sim_print("Infinite loop, press CTRL+C to exit!\n");
        disp[4] = int2asc(count);
        sim_print(disp);

        count++;
    }

    return 0;
}

