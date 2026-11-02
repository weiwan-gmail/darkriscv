# Windows CMake (PC2023 — copy-paste)

Original Make (`make test_verilator`) and Bazel are **unchanged**. This file is
only for `cmake-system/` / `cmake-conan/` on Wei’s worker.

Linux is proven in [`PASS_EVIDENCE.md`](PASS_EVIDENCE.md) and
[`../cmake-conan/PASS_EVIDENCE.md`](../cmake-conan/PASS_EVIDENCE.md). PC2023
smoke of **both** trees is recorded below.

## PC2023 PASS

Worker `D:\CursorWorker`. Develop tip **`b7decce`**
(`b7decce7f85177fc15a93147b8b531cab0ab9395`). Engine:
[withlimon/verilator-windows](https://github.com/withlimon/verilator-windows)
**`verilator_bin.exe`** under MSYS2 MinGW64. Never the extensionless Perl
`verilator`.

| Tree | Tip | Engine | Result |
|------|-----|--------|--------|
| **cmake-system** | `b7decce` on `develop` | withlimon PE `C:\msys64\mingw64\bin\verilator_bin.exe` | PASS (earlier in the same PC2023 campaign) |
| **cmake-conan** | `b7decce` on `develop` (2026-11-02) | same PE; Conan **2.34.0** | `cmake-conan\build_sim.ps1` EXIT 0; ctest **1/1 Passed** (`sim_darksocv`); DarkSoCV teaching sim `verilator_exit=0` |

cmake-conan log on the proof machine:
`D:\CursorWorker\windows-proof-logs\darkriscv-cmake-conan-20261102-170907.log`.

PASS markers are the same as Linux / `make test_verilator`: `Welcome to DarkRISCV!`
/ `SIM DONE` / `ALL TESTS PASSED.` / `verilator_exit=0`.

## Machine notes

| Item | Value |
|------|--------|
| Worker workspace | `D:\CursorWorker` |
| Conan | **2.34.0** (cmake-conan tree only) |
| Verilator | **[withlimon/verilator-windows](https://github.com/withlimon/verilator-windows)** — not a random unofficial drop |
| Engine | **`verilator_bin.exe`** (PE32+). Never the extensionless Perl `verilator` (Explorer/CMD “Open with…” trap). |
| Proven PE on PC2023 | `C:\msys64\mingw64\bin\verilator_bin.exe` |

## withlimon layout

Extract to a **short path without spaces** (withlimon’s example is `D:\verilator`):

```
D:\verilator\
  bin\verilator_bin.exe     PE32+ engine  ← CMake/PowerShell drive this
  bin\verilator.exe         same PE, renamed copy
  bin\verilator.bat         sets VERILATOR_ROOT, then verilator.exe
  bin\verilator             Perl driver, **no extension** — do not invoke
  include\                  (also mirrored under share\verilator\include\)
  README_WINDOWS.txt
```

The withlimon tarball does **not** ship `verilator-config.cmake`. Shared helper
`cmake/DarkriscvSim.cmake` uses bundled `cmake/verilator-config.fallback.cmake`
in that case.

MSYS2 unpack of the same tarball (PC2023 proof path):
`C:\msys64\mingw64\bin\verilator_bin.exe`.

Do **not** run `C:\msys64\mingw64\share\verilator\bin\verilator_bin.exe` — that
file is a Perl wrapper with a `.exe` suffix (not a PE). CMake, `build_sim.ps1`,
and the Conan recipe MZ-check `verilator_bin.exe` and walk from
`VERILATOR_ROOT=share/verilator` up to `mingw64\bin`.

## Environment (once)

User environment (withlimon extract). Skip if the PE is the MSYS2 path above;
`build_sim.ps1` finds it:

```
VERILATOR_ROOT = D:\verilator
PATH          += D:\verilator\bin
```

Firmware: committed `src/darksocv.mem` (C `darkshell`). CMake rebuilds it only
if missing (`make -C src all`, needs RISC-V gcc). Optional: Conan 2.34 on PATH
for `cmake-conan`.

## cmake-system (no Conan)

```bat
cd /d D:\CursorWorker\darkriscv
cd cmake-system
powershell -File .\build_sim.ps1
```

Or by hand (PC2023 PE):

```bat
set VERILATOR_ROOT=C:\msys64\mingw64\share\verilator
set PATH=C:\msys64\mingw64\bin;%PATH%
cmake -S cmake-system -B build-system
cmake --build build-system --config Release --target sim
ctest --test-dir build-system -C Release --output-on-failure
```

`build_sim.ps1` does not pass `-G`; CMake uses the default generator on the
worker. Search order for the PE: `D:\verilator\bin\verilator_bin.exe`, then
`C:\msys64\mingw64\bin\verilator_bin.exe`, then `$VERILATOR_ROOT\bin` and
parents (MZ-checked; Perl wrappers skipped).

## cmake-conan (Conan 2.34 + local recipe)

```bat
cd /d D:\CursorWorker\darkriscv\cmake-conan
conan profile detect --force
powershell -File .\build_sim.ps1
```

The script `conan export`s `recipes/verilator` (withlimon 5.052 tarball, or the
local `D:\verilator` / MSYS2 kit if present) and configures with
`conan_provider.cmake`. `conan install` uses `--no-remote`. Profile file
in-tree: `cmake-conan/profiles/windows-msvc`. `build_sim.ps1` leaves the
provider on **auto-cmake** unless `-Profile` is passed.

## MSVC / MinGW (what this tree actually has)

withlimon is a GCC/MinGW-built **engine**. Host C++ is whatever CMake selected
(`PreferUnixGcc.cmake` is UNIX-only).

| Piece | Windows behavior in this tree |
|-------|-------------------------------|
| `sim/verilator/tb_verilator.cpp` | ISO C++ (`cstdio` / `cstdlib` / `cstring`). No POSIX I/O, so **no** `#if defined(_WIN32)` / `_MSC_VER` port (unlike SERV / PicoRV32 / FemtoRV TBs that needed `unistd.h`). |
| `WIN32` kit find | MZ-check `verilator_bin.exe`; never `share/verilator/bin` Perl wrapper; never extensionless `verilator`. |
| `MSVC` | `include(CheckCXXCompilerFlag)` before `verilate()`, then strip GCC-only `-fcoroutines*`. |
| `cmake/sc_time_stamp.cpp` | Always linked. MSVC has no weak ELF `sc_time_stamp`. |
| `cmake/verilator-config.fallback.cmake` | Skips GCC-only flag probes when the compiler is MSVC. |

This tree does **not** add `/bigobj`, `NOMINMAX`, or `_open`/`_write` CRT shims.
Those exist in sibling forks whose TBs used POSIX APIs; DarkSoCV’s driver does
not.

## Do not

- Do not run extensionless `bin\verilator` from Explorer or CMD.
- Do not point `VERILATOR=` at the Perl driver.
- Do not run `share\verilator\bin\verilator_bin.exe` (Perl wrapper with a `.exe` suffix).
- Do not change original Makefiles or Bazel.
