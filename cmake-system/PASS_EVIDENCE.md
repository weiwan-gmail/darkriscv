# cmake-system PASS evidence (Linux Cursor VM)

Recorded **2026-11-02** on this Cloud Agent Linux VM (`cursor`, Ubuntu, x86_64).
Wraps the proven headless path `sim/verilator/` (same UART protocol as
`make test_verilator`). Make/Bazel were **not** edited.

| Tool | Version |
|------|---------|
| CMake | 3.28.3 |
| g++ | 13.3.0 (`PreferUnixGcc`) |
| Verilator | 5.020 (Debian 5.020-1), `verilator_bin` at `/bin/verilator_bin`, kit `/usr/share/verilator` |
| Conan | not used in this tree |
| Firmware | existing `src/darksocv.mem` (C `darkshell`) |

Windows PC2023 (withlimon `verilator_bin.exe`, worker `D:\CursorWorker`) is a
**follow-up**. PE / MSVC notes: [`WINDOWS.md`](WINDOWS.md).

## Make path still green

```bash
make test_verilator
```

```
Welcome to DarkRISCV!
SIM DONE after 67632 clock cycles
verilator_exit=0
ALL TESTS PASSED.
verilator teaching sim ok.
```

## cmake-system

```bash
cmake -S cmake-system -B build-system -DCMAKE_BUILD_TYPE=Release
cmake --build build-system --target sim
ctest --test-dir build-system --output-on-failure
```

Configure:

```
-- PreferUnixGcc: CMAKE_CXX_COMPILER=/usr/bin/g++
-- DarkriscvSim: VERILATOR_BIN=/bin/verilator_bin
-- DarkriscvSim: VERILATOR_ROOT=/usr/share/verilator
-- DarkriscvSim: firmware /workspace/src/darksocv.mem
-- Executing Verilator...
-- DarkriscvSim: wrap sim/verilator (top darksocv, cwd=/workspace/sim)
-- Configuring done
```

`--target sim`:

```
Welcome to DarkRISCV!
SIM DONE after 67632 clock cycles
verilator_exit=0
ALL TESTS PASSED.
-- DarkSoCV Verilator teaching sim PASS
[100%] Built target sim
```

`ctest`:

```
100% tests passed, 0 tests failed out of 1
```
