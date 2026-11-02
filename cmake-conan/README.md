# cmake-conan — Conan 2 + local Verilator recipe

Same dual-tree shape as [rtl-learning-plan](https://github.com/weiwan-gmail/rtl-learning-plan) / [protosim-apb](https://github.com/weiwan-gmail/protosim-apb). CMakeLists shares [`../cmake/DarkriscvSim.cmake`](../cmake/DarkriscvSim.cmake) with `cmake-system/`; the Verilator kit comes from Conan 2.

Does **not** change Make or Bazel.

## Layout

| Path | Role |
|------|------|
| `CMakeLists.txt` | `PreferUnixGcc` → export local recipe → `conan_provider.cmake` → `DarkriscvSim` |
| `conanfile.py` | `tool_requires("verilator/5.052")` + CMakeDeps build context |
| `conan_provider.cmake` | Vendored [conan-io/cmake-conan](https://github.com/conan-io/cmake-conan) develop2 |
| `recipes/verilator/` | Local recipe: **withlimon** tarball / `D:\verilator` on Windows; system kit on Linux |
| `profiles/linux-gcc` | Linux GCC 13 |
| `profiles/windows-msvc` | VS2022 / MSVC 193 (PC2023 CMake path) |
| `build_sim.ps1` | PC2023 helper |

Targets match cmake-system: `sim_darksocv`, `sim`, `ctest`. See [`../cmake-system/README.md`](../cmake-system/README.md).

## Linux

Needs Conan 2 (`pip install conan`) and a system Verilator kit (`apt install verilator`). The local recipe **packages the system kit** (does not rebuild Verilator from source). `--no-remote` is the default `CONAN_INSTALL_ARGS` so extra remotes cannot prompt for a password.

```bash
export PATH="$HOME/.local/bin:$PATH"   # if pip --user
conan profile detect --force
cmake -S cmake-conan -B build-conan -DCMAKE_BUILD_TYPE=Release
cmake --build build-conan --target sim
ctest --test-dir build-conan --output-on-failure
```

If Conan is missing, use `cmake-system/` instead; this tree still ships.

## Windows (PC2023) — follow-up

| Item | Value |
|------|--------|
| Worker | `D:\CursorWorker` |
| Conan | **2.34** |
| Verilator | [withlimon/verilator-windows](https://github.com/withlimon/verilator-windows) **`verilator_bin.exe`** |

```powershell
cd cmake-conan
.\build_sim.ps1
```

Notes: [`../cmake-system/WINDOWS.md`](../cmake-system/WINDOWS.md). Always the PE `verilator_bin.exe` — never extensionless Perl `verilator`. MSVC: `CheckCXXCompilerFlag` before `verilate()`, then strip `-fcoroutines*`.
