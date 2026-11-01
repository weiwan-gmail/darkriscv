# Proven command logs

Captured on Ubuntu with Icarus 12.0, Verilator 5.020, and
`riscv64-unknown-elf-gcc` 13.2.0. These are real runs, not sketches.

| File | What |
|------|------|
| [01-inspect.txt](01-inspect.txt) | tools, tree, `make toolchain-info` |
| [02-build-firmware.txt](02-build-firmware.txt) | `make -C src clean all` → `darksocv.mem` |
| [03-verilator-build.txt](03-verilator-build.txt) | Verilator compile of DarkSoCV |
| [04-iverilog-darkshell.txt](04-iverilog-darkshell.txt) | `make test_icarus` |
| [05-verilator-darkshell.txt](05-verilator-darkshell.txt) | `make test_verilator` (green command) |

PASS lines to look for: `Welcome to DarkRISCV!`, then (Verilator)
`SIM DONE` / `ALL TESTS PASSED.` / `verilator_exit=0`.
