# cmake-system — system Verilator (no Conan)

Same dual-tree shape as [rtl-learning-plan](https://github.com/weiwan-gmail/rtl-learning-plan) and [protosim-apb](https://github.com/weiwan-gmail/protosim-apb): this tree uses the **already-installed Verilator kit**. It does **not** change Make (`make test_verilator`) or Bazel.

Wraps the proven headless path in `sim/verilator/` (`tb_verilator.cpp` + `rtl.f`). Firmware is still `src/darksocv.mem` via `$readmemh` (run cwd is `sim/`).

| Target | What |
|--------|------|
| `sim_darksocv` | Verilator C++ of DarkSoCV + existing C++ clock driver |
| `sim` | run it; PASS only with `Welcome to DarkRISCV` / `SIM DONE` / `ALL TESTS PASSED.` / `verilator_exit=0` |
| `ctest` | same checks |

Shared helpers: [`../cmake/DarkriscvSim.cmake`](../cmake/DarkriscvSim.cmake), [`../cmake/PreferUnixGcc.cmake`](../cmake/PreferUnixGcc.cmake).

## Linux

```bash
make -C src all   # if src/darksocv.mem is missing
cmake -S cmake-system -B build-system -DCMAKE_BUILD_TYPE=Release
cmake --build build-system --target sim
ctest --test-dir build-system --output-on-failure
```

Linux VM evidence: [`PASS_EVIDENCE.md`](PASS_EVIDENCE.md).

## Windows (PC2023) — follow-up

[withlimon/verilator-windows](https://github.com/withlimon/verilator-windows) + **`verilator_bin.exe`**. Never the extensionless Perl `verilator`. Copy-paste: [`WINDOWS.md`](WINDOWS.md). PC2023 proof of this tree is a follow-up.
