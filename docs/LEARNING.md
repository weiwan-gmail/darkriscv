# DarkRISCV learning index / 学习入口

Primary tutorial (Chinese, for Wei): **[TUTORIAL_zh.md](TUTORIAL_zh.md)**
Shorter English summary: **[TUTORIAL.md](TUTORIAL.md)**
Proven command logs: **[logs/](logs/)**

This fork (`weiwan-gmail/darkriscv`, work on **develop**, parent
[darklife/darkriscv](https://github.com/darklife/darkriscv)) keeps the original
Icarus + C-firmware-`.mem` flow and adds a **headless Verilator C++ clock
driver**. The CPU in `rtl/darkriscv.v` is not rewritten.

**Why hex/mem + Verilator, not a new C ISS:** DarkSoCV already compiles C
(`src/darkshell`) to `src/darksocv.mem`, `$readmemh`s it into BRAM, and UART
`$write`s each TX byte. `sim/verilator/tb_verilator.cpp` only toggles `XCLK` /
`XRES`. That *is* C firmware co-sim for this core. A separate instruction-set
simulator would be a second CPU.

The optional GUI `spidemo` + ImGui path (`sim/cosim.mk`) is unchanged and is
not the documented green command.

## Exact commands (reproduced in `docs/logs/`)

Install tools (Ubuntu/Debian):

```bash
sudo apt-get install -y iverilog verilator gcc-riscv64-unknown-elf build-essential
make toolchain-info
```

### 1) Stock C darkshell on Verilator (documented demo)

```bash
make test_verilator
# expect: Welcome to DarkRISCV! / SIM DONE / ALL TESTS PASSED. / verilator_exit=0
```

Icarus (same `.mem`, same UART protocol):

```bash
make test_icarus
# expect: Welcome to DarkRISCV! / simulation ok.
```

Upstream default (Icarus + VCD) is still:

```bash
make
```

### 2) Optional CMake dual-tree (Make unchanged)

Same `cmake-system/` + `cmake-conan/` shape as
[rtl-learning-plan](https://github.com/weiwan-gmail/rtl-learning-plan).
How-to: [CMAKE.md](../CMAKE.md). Wraps `sim/verilator/` only.

```bash
cmake -S cmake-system -B build-system -DCMAKE_BUILD_TYPE=Release
cmake --build build-system --target sim
ctest --test-dir build-system --output-on-failure
```

Windows PC2023 (withlimon `verilator_bin.exe`): [`WINDOWS.md`](../cmake-system/WINDOWS.md)
(both trees PASS at develop tip `b7decce`).

### 3) Pieces, if you want to run them apart

```bash
make -C src all                 # C → src/darksocv.mem
make -C sim/verilator sim       # Verilator, cwd-sensitive $readmemh
make -C sim NO_WAVE=1           # Icarus without VCD
```

## How to read PASS / FAIL

| Check | Meaning |
|-------|---------|
| UART `$write` of each store to DarkUART TX | printed character (banner + boot lines) |
| stdout `Welcome to DarkRISCV!` | `darkshell` `main()` finished its self-check |
| `debug: *** exception ... breakpoint / load address align` | expected: firmware probes `stvec` |
| prompt `>` then `__INTERACTIVE__ ... ending simulation` | UART raises `ESIMREQ` |
| pipeline report + `$finish` | `__PERFMETER__` on the core |
| `SIM DONE` / `verilator_exit=0` / `ALL TESTS PASSED.` | C++ driver saw `$finish`, not timeout |
| `simulation ok.` | Icarus Makefile finished |

## Next core on the ladder

After this tree is green:

1. **SERV** — bit-serial RISC-V; same ISA, radically different microarchitecture
   (one bit per cycle). Compare with DarkRISCV’s 3-stage DSP-like pipeline.

Previous rungs: tinyriscv → picorv32 → FemtoRV (`learn-fpga`) → **this**.

See the last section of [TUTORIAL_zh.md](TUTORIAL_zh.md).
