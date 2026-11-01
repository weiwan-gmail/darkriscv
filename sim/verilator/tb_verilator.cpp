/*
 * Headless Verilator C++ driver for DarkSoCV.
 *
 * Clock and reset live here because Verilator does not run the #delay
 * generator in sim/darksimv.v. Firmware is still the stock C image
 * (src/darksocv.mem) loaded by $readmemh in rtl/darkram.v.
 *
 * PASS protocol (unchanged RTL): DarkUART $write of each TX byte; the
 * darkshell prompt '>' raises ESIMREQ; the core prints the pipeline
 * report and $finish()es. This file only toggles XCLK / XRES.
 */

#include <cstdio>
#include <cstdlib>
#include <cstring>

#include "verilated.h"
#include "Vdarksocv.h"

#if VM_TRACE
#include "verilated_vcd_c.h"
#endif

static long parse_plus_long(const char *key, long default_value)
{
    const char *p = Verilated::commandArgsPlusMatch(key);
    if (!p || p[0] == '\0')
        return default_value;
    const char *eq = strchr(p, '=');
    if (!eq || eq[1] == '\0')
        return default_value;
    return strtol(eq + 1, NULL, 0);
}

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);

    printf("Built with %s %s.\n", Verilated::productName(), Verilated::productVersion());

    Vdarksocv *top = new Vdarksocv;

#if VM_TRACE
    VerilatedVcdC *tfp = NULL;
    const char *flag_vcd = Verilated::commandArgsPlusMatch("vcd");
    if (flag_vcd && 0 == strcmp(flag_vcd, "+vcd")) {
        Verilated::traceEverOn(true);
        tfp = new VerilatedVcdC;
        top->trace(tfp, 99);
        tfp->open("darksocv_verilator.vcd");
    }
#endif

    const long max_cycles = parse_plus_long("max-cycles", 2000000);
    long cycles = 0;
    int t = 0;
    int exit_code = 0;

    top->XCLK = 0;
    top->XRES = 1;
    top->UART_RXD = 1; /* idle */
    top->IPORT = 0;
    top->eval();

    while (!Verilated::gotFinish()) {
        if (t > 400)
            top->XRES = 0;
        top->XCLK = !top->XCLK;
        top->eval();
#if VM_TRACE
        if (tfp)
            tfp->dump(t);
#endif
        if (top->XCLK) {
            cycles++;
            if (cycles > max_cycles) {
                printf("TIMEOUT after %ld clock cycles\n", cycles);
                printf("verilator_exit=2\n");
                exit_code = 2;
                break;
            }
        }
        t += 5;
    }

    if (exit_code == 0) {
        printf("SIM DONE after %ld clock cycles\n", cycles);
        printf("verilator_exit=0\n");
        printf("ALL TESTS PASSED.\n");
    }

#if VM_TRACE
    if (tfp)
        tfp->close();
#endif
    top->final();
    delete top;
    return exit_code;
}
