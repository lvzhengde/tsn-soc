#include <systemc.h>

//-----------------------------------------------------------------
// Module
//-----------------------------------------------------------------
SC_MODULE(sc_reset_gen)
{
public:
    sc_in <bool>    clk;
    sc_signal<bool> rst_n; //active low

    void thread(void) 
    {
        rst_n.write(false);
        for(int i = 0; i < 5; i++) wait();
        rst_n.write(true);
    }

    SC_HAS_PROCESS(sc_reset_gen);
    sc_reset_gen(sc_module_name name): sc_module(name)
    {
        SC_CTHREAD(thread, clk.pos());   
    }
};
