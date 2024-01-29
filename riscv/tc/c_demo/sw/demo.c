#include <stdint.h>

#define CSR_SIM_CTRL_PUTC (1 << 24)

void sim_print(const char *str) 
{
#ifdef SIMULATION
    int x;
    while (*str != '\0') {
        x = (*str) & 0xff;
        x = x | CSR_SIM_CTRL_PUTC;
        asm volatile ("csrw dscratch, %0" :: "r"(x));

        str++;
    }

    x = '\n' & 0xff;
    x = x | CSR_SIM_CTRL_PUTC;
    asm volatile ("csrw dscratch, %0" :: "r"(x));
#endif
}

int g_mul = 3;
int g_div = 3;

int main()
{
    int i;
    int sum;

    g_mul = 6;
    sum = 0;

    sim_print("ADD Test");
    // sum = 5050
    for (i = 0; i <= 100; i++)
        sum += i;

    sim_print("SUB Test");
    // sum = 3775
    for (i = 0; i <= 50; i++)
        sum -= i;

    sim_print("MUL Test");
    // sum = 22650
    sum = sum * g_mul;

    sim_print("DIV Test");
    // sum = 7550, i.e 0x1d7e
    sum = sum / g_div;

    int t4;

    sim_print("Shift Right Test");
    //t4 = 0x1d7
    t4 = sum >> 4;

    sim_print("Shift Left Test");
    //t4 = 0x1d70
    t4 = t4 << 4;

    sim_print("Logic OR Test");
    //t4 = 0x1d73
    t4 = t4 | 0x3;

    sim_print("Logic AND Test");
    //t4 = 0xd50, i.e. 3408
    t4 = t4 & 0xfd0;

    //display result in C program
    if (t4 == 3408)
        sim_print("Print in C program, demo test PASS!\n");
    else
        sim_print("Print in C program, demo test FAIL!\n");

    //display result in Verilog testbench
    if (t4 == 3408)
        asm("li t3, 0x01");
    else
        asm("li t3, 0x00");

    asm volatile ("addi t4, %0, 0" :: "r"(t4));

    return 0;
}

