#include "sc_reset_gen.h"
#include "testbench.h"
#include <stdlib.h>
#include <math.h>
#include <signal.h>
#include <sys/stat.h>  // mkdir

//--------------------------------------------------------------------
// Defines
//--------------------------------------------------------------------
#ifndef CLK0_PERIOD
    #define CLK0_PERIOD  10
#endif

#ifndef CLK0_NAME
    #define CLK0_NAME  clk
#endif

#ifndef RST0_NAME
    #define RST0_NAME  rst_n
#endif

#define xstr(a) str(a)
#define str(a) #a

//--------------------------------------------------------------------
// Locals
//--------------------------------------------------------------------
static testbench *tb = NULL;

//--------------------------------------------------------------------
// assert_handler: Handling of sc_assert
//--------------------------------------------------------------------
static void assert_handler(const sc_report& rep, const sc_actions& actions)
{
    sc_report_handler::default_handler(rep, actions & ~SC_ABORT);

    if ( actions & SC_ABORT )
    {
        cout << "TEST FAILED" << endl;
        if (tb)
            tb->abort();
        abort();
    }
}
//--------------------------------------------------------------------
// exit_override
//--------------------------------------------------------------------
static void exit_override(void)
{
    if (tb)
        tb->abort();
}
//-----------------------------------------------------------------
// sigint_handler
//-----------------------------------------------------------------
static void sigint_handler(int s)
{
    exit_override();

    // Jump to exit handler!
    exit(1);
}
//--------------------------------------------------------------------
// sc_main
//--------------------------------------------------------------------
int sc_main(int argc, char* argv[])
{
    bool trace            = false;
    int seed              = 1;
    int last_argc         = 0;
    const char * vcd_name = "logs/sysc_wave";

    // Env variable seed override
    char *s = getenv("SEED");
    if (s && strcmp(s, ""))
        seed = strtol(s, NULL, 0);

    for (int i=1;i<argc;i++)
    {
        if (!strcmp(argv[i], "--trace"))
        {
            trace = strtol(argv[i+1], NULL, 0);
            i++;
        }
        else if (!strcmp(argv[i], "--seed"))
        {
            seed = strtol(argv[i+1], NULL, 0);
            i++;
        }
        else if (!strcmp(argv[i], "--vcd_name"))
        {
            vcd_name = (const char*)argv[i+1];
            i++;
        }
        else
        {
            last_argc = i-1;
            break;
        }
    }

    // Enable waves override
    s = getenv("ENABLE_WAVES");
    if (s && !strcmp(s, "no"))
        trace = 0;    

    sc_report_handler::set_actions("/IEEE_Std_1666/deprecated", SC_DO_NOTHING);

    // Register custom assert handler
    sc_report_handler::set_handler(assert_handler);

    // Capture exit
    atexit(exit_override);

    // Catch SIGINT to restore terminal settings on exit
    signal(SIGINT, sigint_handler);

    // Seed
    srand(seed);

    // Prevent unused variable warnings
    if (false && argc && argv) {}

    // Create logs/ directory in case we have traces to put under it
    Verilated::mkdir("logs");

    // Set debug level, 0 is off, 9 is highest presently used
    // May be overridden by commandArgs argument parsing
    Verilated::debug(0);

    // Randomization reset policy
    // May be overridden by commandArgs argument parsing
    Verilated::randReset(2);

#if VM_TRACE
    // Before any evaluation, need to know to calculate those signals only used for tracing
    Verilated::traceEverOn(true);
#endif

    // Pass arguments so Verilated code can see them, e.g. $value$plusargs
    // This needs to be called before you create any model
    Verilated::commandArgs(argc, argv);

    // General logfile
    std::ios::sync_with_stdio();

    // Clocks
    sc_clock CLK0_NAME (xstr(CLK0_NAME), CLK0_PERIOD, SC_NS);
    sc_reset_gen clk0_rst(xstr(RST0_NAME));
                 clk0_rst.clk(CLK0_NAME);

    // Testbench
    tb = new testbench("tb");
    tb->CLK0_NAME(CLK0_NAME);
    tb->RST0_NAME(clk0_rst.rst_n);

    tb->set_argcv(argc - last_argc, &argv[last_argc]);

    // You must do one evaluation before enabling waves, in order to allow
    // SystemC to interconnect everything for testing.
    sc_start(SC_ZERO_TIME);

#if VM_TRACE
    VerilatedVcdSc* tfp = nullptr;
    std::cout << "Enabling waves into logs/vlt_dump.vcd...\n";
    tfp = new VerilatedVcdSc;
    tb->m_dut->m_rtl->trace(tfp, 99);  // Trace 99 levels of hierarchy
    tfp->open("logs/vlt_dump.vcd");

    tb->init_trace_ptr(tfp);
#endif
    tb->set_dpi_scope("tb.DUT.Vriscv_tcm_top.riscv_tcm_top.u_tcm");

    // Waves
    if (trace)
        tb->add_trace(sc_create_vcd_trace_file(vcd_name), "");


    // Go!
    //sc_start();
    while (!Verilated::gotFinish()) {
#if VM_TRACE
        // Flush the wave files each cycle so we can immediately see the output
        // Don't do this in "real" programs, do it in an abort() handler instead
        if (tfp) tfp->flush();
#endif
        // Simulate 1ns
        sc_start(1, SC_NS);
    }

    // Final model cleanup
    tb->m_dut->m_rtl->final();

    // Close trace if opened
#if VM_TRACE
    if (tfp) {
        tfp->close();
        tfp = nullptr;
    }    
#endif

    return 0;
}
