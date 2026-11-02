# CMake dual-tree (optional)

Same layout as [rtl-learning-plan](https://github.com/weiwan-gmail/rtl-learning-plan) and ProtoSim: **`cmake-system/`** (system Verilator) and **`cmake-conan/`** (Conan 2 local recipe). Shared helpers live in [`cmake/`](cmake/).

This does **not** replace Make or Bazel. Default `make` is still Icarus; `make test_verilator` is still the teaching command. CMake only wraps that known-green Verilator path (`sim/verilator/tb_verilator.cpp` + `rtl.f` + `src/darksocv.mem`).

Need `src/darksocv.mem` first (committed in git; `make -C src all` if it is missing).

## cmake-system (Linux)

```bash
cmake -S cmake-system -B build-system -DCMAKE_BUILD_TYPE=Release
cmake --build build-system --target sim
ctest --test-dir build-system --output-on-failure
```

PASS: `Welcome to DarkRISCV!` / `SIM DONE` / `ALL TESTS PASSED.` / `verilator_exit=0`. Evidence: [`cmake-system/PASS_EVIDENCE.md`](cmake-system/PASS_EVIDENCE.md).

## cmake-conan (Linux)

Conan 2 (`pip install conan`) packages the **system** Verilator kit; it does not rebuild Verilator. Install uses `--no-remote`.

```bash
export PATH="$HOME/.local/bin:$PATH"
conan profile detect --force
cmake -S cmake-conan -B build-conan -DCMAKE_BUILD_TYPE=Release
cmake --build build-conan --target sim
ctest --test-dir build-conan --output-on-failure
```

Evidence: [`cmake-conan/PASS_EVIDENCE.md`](cmake-conan/PASS_EVIDENCE.md).

## Windows (PC2023)

Proven on worker PC2023 at develop tip **`b7decce`**. Drive
[withlimon/verilator-windows](https://github.com/withlimon/verilator-windows)
**`verilator_bin.exe`** (PE). Never the extensionless Perl `verilator`.
Helpers: `cmake-system/build_sim.ps1`, `cmake-conan/build_sim.ps1`.
How-to + PASS table: [`cmake-system/WINDOWS.md`](cmake-system/WINDOWS.md).

```bat
cd cmake-system
powershell -File .\build_sim.ps1
```

```bat
cd cmake-conan
powershell -File .\build_sim.ps1
```

PC2023 cmake-conan (Conan 2.34.0, PE `C:\msys64\mingw64\bin\verilator_bin.exe`):
EXIT 0, ctest 1/1 Passed (`sim_darksocv`), `verilator_exit=0`. cmake-system
PASS earlier in the same campaign with the same PE.
