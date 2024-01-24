#include <stdint.h>

#include "utils.h"


extern void trap_entry();


void _init()
{
    // Interrupt/exception entry function
    write_csr(mtvec, &trap_entry);

    // Enable global interrupt
    // MIE = 1, MPIE = 1, MPP = 11
    write_csr(mstatus, 0x1888);
}
