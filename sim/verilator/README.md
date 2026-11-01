# Headless Verilator (teaching path)

This directory compiles **DarkSoCV** with Verilator and drives `XCLK` /
`XRES` from C++. Firmware is the stock C `darkshell` image
(`src/darksocv.mem`) loaded by `$readmemh` in `rtl/darkram.v`.

That is C firmware co-sim for this core: the CPU executes the cross-compiled
image; the C++ file is not a second instruction-set simulator.

The GUI / ImGui `spidemo` path in `sim/cosim.mk` is unchanged and optional.

```bash
make -C src all                 # C → src/darksocv.mem
make -C sim/verilator sim       # or from repo root: make test_verilator
```

PASS lines: `Welcome to DarkRISCV!`, then the prompt ends the sim, then
`SIM DONE` / `ALL TESTS PASSED.` / `verilator_exit=0`.

Optional VCD: `make TRACE=1 sim PLUSARGS=+vcd` (from this directory).
