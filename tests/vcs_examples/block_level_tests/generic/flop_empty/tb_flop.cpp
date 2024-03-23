#include <verilated.h>
#include "Vtop_flop.h" // Generated model header for top_flop
#include <verilated_vcd_c.h> // Header for VCD tracing

vluint64_t main_time = 0; // Current simulation time

// Called by $time in Verilog
double sc_time_stamp() {
    return main_time; // Note does conversion to real, to match SystemC
}

int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv); // Initialize Verilator's variables
    Vtop_flop* top = new Vtop_flop; // Create an instance of our module under test
    
    Verilated::traceEverOn(true); // Enable waveform generation
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99); // Trace 99 levels of hierarchy
    tfp->open("top_flop.vcd"); // Open the waveform output

    top->reset = 1; // Start in reset

    while (main_time < 1000 && !Verilated::gotFinish()) {
        if (main_time % 10 == 0) {
            top->clk = !top->clk; // Toggle clock every 10 simulation cycles
        }
        if (main_time == 15) {
            top->reset = 0; // Release reset
        }

        // Randomly manipulate inputs every cycle after reset
        if (main_time > 15) {
            top->set = rand() % 2;
            top->clear = rand() % 2;
            top->en = rand() % 2;
            top->load = rand() % 2;
            top->d = rand() % 256;
            top->val = rand() % 256;
            top->d_sync = rand() % 2;
        }

        top->eval(); // Evaluate model
        tfp->dump(main_time); // Dump trace data for this cycle

        main_time++; // Time passes...
    }

    top->final(); // Done simulating
    tfp->close(); // Close the waveform
    delete top;
    delete tfp;
    return 0;
}

