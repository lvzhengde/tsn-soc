#include "testbench_vbase.h"
#include "elf_load.h"
#include <getopt.h>
#include <unistd.h>

#include "riscv_tcm_top_rtl.h"
#include "Vriscv_tcm_top.h"
#include "Vriscv_tcm_top__Dpi.h"

#include "verilated.h"
#include "verilated_vcd_sc.h"

#define MEM_BASE 0x00000000
#define MEM_SIZE (64 * 1024)

//-----------------------------------------------------------------
// Command line options
//-----------------------------------------------------------------
#define GETOPTS_ARGS "f:c:h"

static struct option long_options[] =
{
    {"bin",        required_argument, 0, 'f'},
    {"cycles",     required_argument, 0, 'c'},
    {"help",       no_argument,       0, 'h'},
    {0, 0, 0, 0}
};

static void help_options(void)
{
    fprintf (stderr,"Usage:\n");
    fprintf (stderr,"  --bin         | -f FILE       File to load\n");
    fprintf (stderr,"  --cycles      | -c NUM        Max cycles to execute\n");
    exit(-1);
}

//-----------------------------------------------------------------
// Module
//-----------------------------------------------------------------
class testbench: public testbench_vbase, public mem_api
{
public:
    //-----------------------------------------------------------------
    // Instances / Members
    //-----------------------------------------------------------------      
    riscv_tcm_top_rtl           *m_dut;

    int                          m_argc;
    char**                       m_argv;

    std::string                  m_dpi_scope;

    //-----------------------------------------------------------------
    // Signals
    //-----------------------------------------------------------------    
    sc_signal <bool>             rst_cpu_in;

    sc_signal <axi4_master>      axi_t_in;
    sc_signal <axi4_slave>       axi_t_out;

    sc_signal <axi4_lite_master> axi_i_out;
    sc_signal <axi4_lite_slave>  axi_i_in;

    sc_signal < sc_uint <32> >   intr_in;


    //-----------------------------------------------------------------
    // process: Main loop for CPU execution
    //-----------------------------------------------------------------
    void process(void) 
    {
        uint64_t       cycles         = 0;
        int64_t        max_cycles     = (int64_t)-1;
        const char *   filename       = NULL;
        int            help           = 0;
        int c;        

        int option_index = 0;
        while ((c = getopt_long (m_argc, m_argv, GETOPTS_ARGS, long_options, &option_index)) != -1)
        {
            switch(c)
            {
                case 'f':
                    filename = optarg;
                    break;
                case 'c':
                    max_cycles = (int64_t)strtoull(optarg, NULL, 0);
                    break;
                case '?':
                default:
                    help = 1;   
                    break;
            }
        }        

        if(m_argc == 1)
        {
            const char test_bin[] = "./tcm.bin";
            filename = test_bin;
            fprintf (stderr,"BIN file used:  %s\n", filename);
        }

        if (help || filename == NULL)
        {
            help_options();
            sc_stop();
            return;
        }

        // Force CPU into reset
        rst_cpu_in.write(true);
        
        // Load Firmware
        printf("Running: %s\n", filename);

        //FIXME. can not use elf_load due to unknown bug.
#if 0
        elf_load elf(filename, this);
        if (!elf.load())
        {
            fprintf (stderr,"Error: Could not open %s\n", filename);
            sc_stop();
        }
#endif

        if (!tcm_load(filename))
        {
            sc_stop();
        }
        
        // Release CPU reset after TCM memory loaded
        for(int i = 0; i < 7; i++) wait();
        rst_cpu_in.write(false);

        while (true)
        {
            cycles += 1;
            if (cycles >= max_cycles && max_cycles != -1)
                break;

            wait();
        }

        sc_stop();        
    }

    void set_argcv(int argc, char* argv[]) { m_argc = argc; m_argv = argv; }

    //-----------------------------------------------------------------
    // Construction
    //-----------------------------------------------------------------
    SC_HAS_PROCESS(testbench);
    testbench(sc_module_name name): testbench_vbase(name)
    {
        m_dut = new riscv_tcm_top_rtl("DUT");
        m_dut->clk_in(clk);
        m_dut->rst_in(rst);
        m_dut->rst_cpu_in(rst_cpu_in);
        m_dut->axi_t_out(axi_t_out);
        m_dut->axi_t_in(axi_t_in);
        m_dut->axi_i_out(axi_i_out);
        m_dut->axi_i_in(axi_i_in);
        m_dut->intr_in(intr_in);
    }

    //-----------------------------------------------------------------
    // Trace
    //-----------------------------------------------------------------
    void add_trace(sc_trace_file * fp, std::string prefix)
    {
        if (!waves_enabled())
            return;

        // Add signals to trace file
        #define TRACE_SIGNAL(a) sc_trace(fp,a,#a);
        TRACE_SIGNAL(clk);
        TRACE_SIGNAL(rst);

        m_dut->add_trace(fp, "");
    }

    //-----------------------------------------------------------------
    // create_memory: Create memory region
    //-----------------------------------------------------------------
    bool create_memory(uint32_t base, uint32_t size, uint8_t *mem = NULL)
    {
        sc_assert(base >= MEM_BASE && ((base + size) < (MEM_BASE + MEM_SIZE)));
        return true;
    }
    //-----------------------------------------------------------------
    // valid_addr: Check address range
    //-----------------------------------------------------------------
    bool valid_addr(uint32_t addr) { return true; } 
    //-----------------------------------------------------------------
    // write: Write byte into memory
    //-----------------------------------------------------------------
    void write(uint32_t addr, uint8_t data)
    {
        write_ram(addr, data);
    }
    //-----------------------------------------------------------------
    // write: Read byte from memory
    //-----------------------------------------------------------------
    uint8_t read(uint32_t addr)
    {
        return read_ram(addr);
    }

    //set DPI scope
    void set_dpi_scope(const char* dpi_scope)
    {
        m_dpi_scope = dpi_scope;

        //set scope for DPI functions
        const svScope scope = svGetScopeFromName(m_dpi_scope.c_str());
        assert(scope); // Check for nullptr if scope not found
        svSetScope(scope);
    }

    bool tcm_load(const char* filename)
    {
        unsigned char mem[65536];

        //initial tcm memory to 0
        for (int i = 0; i < 65536; i++)
            this->write(i, 0);

        //load tcm.bin to tcm memory
        FILE *f = fopen(filename, "rb"); 
        if (f == NULL) {
            printf("Failed to open binary file %s for TCM\n", filename);
            return false;
        }

        size_t bytesRead = fread(mem, sizeof(unsigned char), 65536, f);
        fclose(f);

        for (int i = 0; i < 65536; i++)
            this->write(i, mem[i]);

        return true;
    }
};
