# RISC-V Instruction Set Simulator

A simple RISC-V instruction set simulator for RV32IM.
<br>
Adapted from<br>
Github: http://github.com/ultraembedded/riscv_soc <br>

## Building

Dependencies;
* gcc
* make
* libelf
* libbfd

To install the dependencies on Linux Ubuntu/Mint;
```
sudo apt-get install libelf-dev binutils-dev
```

To build the executable, type:
```
make
````

## Usage

The simulator will load and run a compiled ELF (compiled with RV32I or RV32IM compiler options);
```
# Using a makerule
make run

# Or running directly
./riscv-sim -f images/basic.elf
./riscv-sim -f images/linux.elf -b 0x80000000 -s 33554432
```

There are two example pre-compiled ELFs provided, one which is a basic machine mode only test program, and one
which boots Linux (modified 4.19 compiled for RV32IM).

## Extensions

The following primitives can be used to print to the console or to exit a simulation;
```

#define CSR_SIM_CTRL_EXIT (0 << 24)
#define CSR_SIM_CTRL_PUTC (1 << 24)

static inline void sim_exit(int exitcode)
{
    unsigned int arg = CSR_SIM_CTRL_EXIT | ((unsigned char)exitcode);
    asm volatile ("csrw dscratch,%0": : "r" (arg));
}

static inline void sim_putc(int ch)
{
    unsigned int arg = CSR_SIM_CTRL_PUTC | (ch & 0xFF);
    asm volatile ("csrw dscratch,%0": : "r" (arg));
}
```

## Disclaimer

This design can be freely used without any fees charged by the developer. <br>
The solutions involved in the design may implicitly involve some patent claims of organizations or individuals, and the patent rights belong to the relevant owners. <br>
The developer makes no commitment to the results of the use and assumes no legal responsibility arising from it. <br>
Users must be aware of and agree to the above statement. If you do not agree, please do not use it. <br>

## Follow the Developer's Wechat Official Accountp
If you need to know the latest status of the project and participate in related technical discussions, please open WeChat and search for the official account "时光之箭" or scan the following QR code to follow the Developer's Wechat official account. <br>
![image](https://open.weixin.qq.com/qr/code?username=Arrow-of-Time-zd "时光之箭")
