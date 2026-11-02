# cmake-conan PASS evidence (Linux Cursor VM)

Recorded **2026-11-02** on this Cloud Agent Linux VM (`cursor`, Ubuntu, x86_64).
Same wrap as cmake-system (`cmake/DarkriscvSim.cmake`); Verilator kit via
Conan 2 local recipe. Make/Bazel were **not** edited.

| Tool | Version |
|------|---------|
| CMake | 3.28.3 |
| g++ | 13.3.0 (`PreferUnixGcc`; `conan profile detect` guessed clang, provider used **auto-cmake → gcc 13**) |
| Verilator | local recipe `verilator/5.052` **packaged the system 5.020 kit** (did not rebuild from source) |
| Conan | **2.34.0** (`pip install --user conan`) — same major/minor as PC2023 |
| Firmware | existing `src/darksocv.mem` (C `darkshell`) |

Windows PC2023 (Conan **2.34.0** + withlimon `verilator_bin.exe` at
`C:\msys64\mingw64\bin\verilator_bin.exe`, worker `D:\CursorWorker`, develop
tip `b7decce`) is **PASS**: `build_sim.ps1` EXIT 0, ctest 1/1 (`sim_darksocv`),
`verilator_exit=0`. How-to and table: [`../cmake-system/WINDOWS.md`](../cmake-system/WINDOWS.md).

## Configure

```bash
export PATH="$HOME/.local/bin:$PATH"
conan profile detect --force
cmake -S cmake-conan -B build-conan -DCMAKE_BUILD_TYPE=Release
```

Conan install used in-tree `recipes/verilator` (`tool_requires("verilator/5.052")`)
with `--build=missing --no-remote`. Package folder supplied `VERILATOR_ROOT` /
`include/verilated.h`; `verilate()` came from the packaged kit cmake + DarkriscvSim.

```
======== Installing packages ========
-------- Installing package verilator/5.052 ...
Calling package()
package(): Packaged 1 '.cmake' file: verilator-config.cmake
...
Install finished successfully
-- DarkriscvSim: Conan package folder /home/ubuntu/.conan2/p/b/veril.../p
-- DarkriscvSim: VERILATOR_BIN=.../p/bin/verilator_bin
-- DarkriscvSim: VERILATOR_ROOT=.../p
-- Executing Verilator...
-- Configuring done
```

## sim / ctest

```bash
cmake --build build-conan --target sim
ctest --test-dir build-conan --output-on-failure
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

`ctest`: **100% tests passed, 0 tests failed out of 1**.
