# Shared Verilator CMake helpers for darkriscv (cmake-system/ and cmake-conan/).
# Same dual-tree kit logic as weiwan-gmail/rtl-learning-plan RtlLabSim.cmake
# and weiwan-gmail/protosim-apb ApbSim.cmake.
#
# Wraps the known-green headless path in sim/verilator/ (tb_verilator.cpp +
# rtl.f). Does not replace Make / Bazel, and does not reimplement DarkSoCV.
#
# - Locate the Verilator kit; on Windows always drive verilator_bin.exe PE
#   (withlimon: https://github.com/withlimon/verilator-windows). Never the
#   extensionless Perl `verilator` (Explorer/CMD Open-with trap).
# - include(CheckCXXCompilerFlag) before verilate().
# - On MSVC, strip GCC-only -fcoroutines* flags Verilator may inject.
# - Provide sc_time_stamp() (MSVC has no weak ELF symbols).

include_guard(GLOBAL)

set(DARKRISCV_CMAKE_DIR "${CMAKE_CURRENT_LIST_DIR}")
get_filename_component(DARKRISCV_REPO_ROOT "${DARKRISCV_CMAKE_DIR}/.." ABSOLUTE)

# Flags copied from sim/verilator/Makefile (proven teaching path).
set(DARKRISCV_VERILATOR_ARGS
  --relative-includes
  --no-timing
  -I${DARKRISCV_REPO_ROOT}/rtl
  -Wno-fatal
  -Wno-WIDTHTRUNC
  -Wno-WIDTHEXPAND
  -Wno-UNUSEDSIGNAL
  -Wno-UNUSEDPARAM
  -Wno-PINCONNECTEMPTY
  -Wno-PINMISSING
  -Wno-CASEINCOMPLETE
  -Wno-CASEX
  -Wno-TIMESCALEMOD
  -Wno-UNSIGNED
  -Wno-REALCVT
  -Wno-BLKANDNBLK
  -Wno-UNOPTFLAT
)

set(DARKRISCV_RTL_SOURCES
  "${DARKRISCV_REPO_ROOT}/rtl/darksocv.v"
  "${DARKRISCV_REPO_ROOT}/rtl/darkbridge.v"
  "${DARKRISCV_REPO_ROOT}/rtl/darkuart.v"
  "${DARKRISCV_REPO_ROOT}/rtl/darkriscv.v"
  "${DARKRISCV_REPO_ROOT}/rtl/darkpll.v"
  "${DARKRISCV_REPO_ROOT}/rtl/darkram.v"
  "${DARKRISCV_REPO_ROOT}/rtl/darkio.v"
  "${DARKRISCV_REPO_ROOT}/rtl/darkcache.v"
  "${DARKRISCV_REPO_ROOT}/rtl/darkmac.v"
  "${DARKRISCV_REPO_ROOT}/rtl/lib/sdram/mt48lc16m16a2_ctrl.v"
)

# MSYS2 names a Perl script share/verilator/bin/verilator_bin.exe. withlimon
# and mingw64/bin ship a real PE (MZ). Only the PE may be executed on Windows.
function(darkriscv_windows_file_is_pe filepath outvar)
  set(_ok FALSE)
  if(EXISTS "${filepath}")
    file(READ "${filepath}" _magic HEX LIMIT 2)
    string(TOUPPER "${_magic}" _magic)
    if(_magic STREQUAL "4D5A")
      set(_ok TRUE)
    endif()
  endif()
  set(${outvar} ${_ok} PARENT_SCOPE)
endfunction()

function(darkriscv_find_windows_pe outvar)
  unset(DARKRISCV_VERILATOR_BIN CACHE)
  set(_cands "")
  # Known PE bindirs first. $VERILATOR_ROOT/bin on MSYS2 is the Perl wrapper.
  list(APPEND _cands
    "D:/verilator/bin/verilator_bin.exe"
    "C:/msys64/mingw64/bin/verilator_bin.exe")
  if(DEFINED ENV{VERILATOR_ROOT} AND NOT "$ENV{VERILATOR_ROOT}" STREQUAL "")
    list(APPEND _cands
      "$ENV{VERILATOR_ROOT}/bin/verilator_bin.exe"
      "$ENV{VERILATOR_ROOT}/../bin/verilator_bin.exe"
      "$ENV{VERILATOR_ROOT}/../../bin/verilator_bin.exe")
  endif()
  foreach(_c IN LISTS _cands)
    get_filename_component(_abs "${_c}" ABSOLUTE)
    darkriscv_windows_file_is_pe("${_abs}" _ispe)
    if(_ispe)
      set(${outvar} "${_abs}" PARENT_SCOPE)
      return()
    endif()
  endforeach()
  find_program(_dr_path_pe NAMES verilator_bin.exe)
  if(_dr_path_pe)
    darkriscv_windows_file_is_pe("${_dr_path_pe}" _ispe)
    if(_ispe)
      set(${outvar} "${_dr_path_pe}" PARENT_SCOPE)
      return()
    endif()
  endif()
  set(${outvar} "" PARENT_SCOPE)
endfunction()

function(darkriscv_locate_verilator_kit)
  set(_root "")

  if(WIN32)
    darkriscv_find_windows_pe(_pe)
    if(NOT _pe)
      message(FATAL_ERROR
        "Windows Verilator PE not found (verilator_bin.exe with MZ header).\n"
        "Install the withlimon build: https://github.com/withlimon/verilator-windows\n"
        "Extract to a short path (e.g. D:\\verilator), then:\n"
        "  VERILATOR_ROOT = D:\\verilator\n"
        "  PATH          += D:\\verilator\\bin\n"
        "Do NOT invoke the extensionless Perl `verilator` (Open-with trap).\n"
        "Do NOT invoke share/verilator/bin/verilator_bin.exe (Perl wrapper with a .exe suffix).\n"
        "PC2023 worker workspace: D:\\CursorWorker")
    endif()
    set(DARKRISCV_VERILATOR_BIN "${_pe}")
  else()
    # Do not pre-set the result variable — find_program skips the search if it
    # is already defined (even as "").
    unset(DARKRISCV_VERILATOR_BIN CACHE)
    find_program(DARKRISCV_VERILATOR_BIN NAMES verilator_bin HINTS
      "$ENV{VERILATOR_ROOT}/bin"
      /usr/bin
      /usr/local/bin)
    if(NOT DARKRISCV_VERILATOR_BIN)
      message(FATAL_ERROR
        "verilator_bin not found. Install Verilator 5.x (e.g. apt install verilator).")
    endif()
  endif()
  set(_pe "${DARKRISCV_VERILATOR_BIN}")

  get_filename_component(_bin "${_pe}" DIRECTORY)
  get_filename_component(_parent "${_bin}" DIRECTORY)
  foreach(_c
      "$ENV{VERILATOR_ROOT}"
      "${_parent}"
      "${_parent}/share/verilator"
      "/usr/share/verilator"
      "/usr/local/share/verilator"
      "D:/verilator"
      "C:/msys64/mingw64/share/verilator")
    if(_c AND EXISTS "${_c}/include/verilated.h")
      set(_root "${_c}")
      break()
    endif()
  endforeach()

  if(NOT _root)
    message(FATAL_ERROR
      "VERILATOR_ROOT kit not found (need include/verilated.h). PE was ${_pe}")
  endif()

  message(STATUS "DarkriscvSim: VERILATOR_BIN=${_pe}")
  message(STATUS "DarkriscvSim: VERILATOR_ROOT=${_root}")
  set(DARKRISCV_VERILATOR_BIN "${_pe}" PARENT_SCOPE)
  set(DARKRISCV_VERILATOR_ROOT "${_root}" PARENT_SCOPE)
endfunction()

function(darkriscv_find_verilator)
  # Pre-seed VERILATOR_BIN so a Debian/Ubuntu verilator-config.cmake does not
  # FATAL (it searches only VERILATOR_ROOT/bin with NO_CMAKE_SYSTEM_PATH), and
  # so an MSYS2 kit config does not pick share/verilator/bin's Perl wrapper.
  if(WIN32)
    darkriscv_find_windows_pe(_pe_seed)
    if(_pe_seed)
      set(DARKRISCV_VERILATOR_BIN "${_pe_seed}" CACHE FILEPATH "DARKRISCV_VERILATOR_BIN" FORCE)
      set(VERILATOR_BIN "${_pe_seed}" CACHE FILEPATH "VERILATOR_BIN" FORCE)
    endif()
  else()
    find_program(DARKRISCV_VERILATOR_BIN NAMES verilator_bin HINTS
      "$ENV{VERILATOR_ROOT}/bin" /usr/bin /usr/local/bin)
    if(DARKRISCV_VERILATOR_BIN)
      set(VERILATOR_BIN "${DARKRISCV_VERILATOR_BIN}" CACHE FILEPATH "VERILATOR_BIN" FORCE)
    endif()
  endif()

  # First find_package() triggers cmake-conan if the provider is registered.
  find_package(verilator QUIET)

  foreach(_pkg_var
      verilator_PACKAGE_FOLDER_RELEASE
      verilator_PACKAGE_FOLDER_RELWITHDEBINFO
      verilator_PACKAGE_FOLDER_DEBUG
      verilator_PACKAGE_FOLDER)
    if(DEFINED ${_pkg_var} AND EXISTS "${${_pkg_var}}/include/verilated.h")
      set(ENV{VERILATOR_ROOT} "${${_pkg_var}}")
      # Prefer the packaged PE (withlimon on Windows) over a stale PATH hit.
      unset(DARKRISCV_VERILATOR_BIN CACHE)
      message(STATUS "DarkriscvSim: Conan package folder ${${_pkg_var}}")
      break()
    endif()
  endforeach()

  darkriscv_locate_verilator_kit()
  set(VERILATOR_ROOT "${DARKRISCV_VERILATOR_ROOT}" CACHE PATH "VERILATOR_ROOT" FORCE)
  set(verilator_ROOT "${DARKRISCV_VERILATOR_ROOT}" CACHE PATH "verilator_ROOT" FORCE)
  set(VERILATOR_BIN "${DARKRISCV_VERILATOR_BIN}" CACHE FILEPATH "VERILATOR_BIN" FORCE)
  set(ENV{VERILATOR_ROOT} "${DARKRISCV_VERILATOR_ROOT}")

  if(NOT COMMAND verilate)
    if(EXISTS "${DARKRISCV_VERILATOR_ROOT}/verilator-config.cmake")
      include("${DARKRISCV_VERILATOR_ROOT}/verilator-config.cmake")
    else()
      message(STATUS
        "DarkriscvSim: kit has no verilator-config.cmake (typical of withlimon); "
        "using bundled cmake/verilator-config.fallback.cmake")
      include("${DARKRISCV_CMAKE_DIR}/verilator-config.fallback.cmake")
    endif()
  endif()

  # Kit configs may find_program() VERILATOR_ROOT/bin (Perl wrapper on MSYS2).
  # Re-assert the PE after that include so verilate() drives verilator_bin.exe.
  if(WIN32)
    set(VERILATOR_BIN "${DARKRISCV_VERILATOR_BIN}" CACHE FILEPATH "VERILATOR_BIN" FORCE)
    darkriscv_windows_file_is_pe("${VERILATOR_BIN}" _bin_is_pe)
    if(NOT _bin_is_pe)
      darkriscv_find_windows_pe(_pe_fix)
      if(NOT _pe_fix)
        message(FATAL_ERROR
          "VERILATOR_BIN is not a PE engine: ${VERILATOR_BIN}\n"
          "Do not use share/verilator/bin/verilator_bin.exe (Perl wrapper).")
      endif()
      set(DARKRISCV_VERILATOR_BIN "${_pe_fix}" CACHE FILEPATH "DARKRISCV_VERILATOR_BIN" FORCE)
      set(VERILATOR_BIN "${_pe_fix}" CACHE FILEPATH "VERILATOR_BIN" FORCE)
      message(STATUS "DarkriscvSim: replaced non-PE VERILATOR_BIN with ${_pe_fix}")
    endif()
  endif()

  if(NOT COMMAND verilate)
    message(FATAL_ERROR "verilate() missing after Verilator package load")
  endif()
endfunction()

function(darkriscv_strip_msvc_gcc_flags target)
  if(NOT MSVC)
    return()
  endif()
  foreach(_prop COMPILE_OPTIONS INTERFACE_COMPILE_OPTIONS)
    get_target_property(_opts ${target} ${_prop})
    if(_opts)
      list(FILTER _opts EXCLUDE REGEX "fcoroutines")
      set_property(TARGET ${target} PROPERTY ${_prop} "${_opts}")
    endif()
  endforeach()
endfunction()

function(darkriscv_ensure_firmware)
  set(_mem "${DARKRISCV_REPO_ROOT}/src/darksocv.mem")
  if(EXISTS "${_mem}")
    message(STATUS "DarkriscvSim: firmware ${_mem}")
    return()
  endif()
  find_program(_dr_make NAMES gmake make)
  if(NOT _dr_make)
    message(FATAL_ERROR
      "src/darksocv.mem missing and make not found. Run: make -C src all")
  endif()
  message(STATUS "DarkriscvSim: building firmware via make -C src all")
  execute_process(
    COMMAND "${_dr_make}" -C "${DARKRISCV_REPO_ROOT}/src" all
    RESULT_VARIABLE _rc
    OUTPUT_VARIABLE _out
    ERROR_VARIABLE _err)
  if(_rc OR NOT EXISTS "${_mem}")
    message(FATAL_ERROR
      "Failed to build src/darksocv.mem (rc=${_rc}). Need RISC-V gcc.\n${_out}\n${_err}")
  endif()
endfunction()

function(darkriscv_add_sim)
  set(_tb "${DARKRISCV_REPO_ROOT}/sim/verilator/tb_verilator.cpp")
  if(NOT EXISTS "${_tb}")
    message(FATAL_ERROR "DarkriscvSim: missing ${_tb}")
  endif()
  foreach(_s IN LISTS DARKRISCV_RTL_SOURCES)
    if(NOT EXISTS "${_s}")
      message(FATAL_ERROR "DarkriscvSim: RTL not found: ${_s}")
    endif()
  endforeach()

  add_executable(sim_darksocv
    "${_tb}"
    "${DARKRISCV_CMAKE_DIR}/sc_time_stamp.cpp")
  target_compile_features(sim_darksocv PRIVATE cxx_std_17)

  # Verilator's verilate() calls check_cxx_compiler_flag() (coroutines /
  # TIMING path). Include the module first; MSVC then gets flag stripping.
  include(CheckCXXCompilerFlag)

  verilate(sim_darksocv
    PREFIX Vdarksocv
    TOP_MODULE darksocv
    SOURCES ${DARKRISCV_RTL_SOURCES}
    VERILATOR_ARGS ${DARKRISCV_VERILATOR_ARGS}
  )
  darkriscv_strip_msvc_gcc_flags(sim_darksocv)
endfunction()

function(darkriscv_sim_setup)
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
  endif()
  set(CMAKE_CXX_STANDARD 17)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)

  darkriscv_find_verilator()
  include(CheckCXXCompilerFlag)
  darkriscv_ensure_firmware()
  darkriscv_add_sim()

  set(_sim "${DARKRISCV_REPO_ROOT}/sim")
  add_custom_target(sim
    DEPENDS sim_darksocv
    COMMAND ${CMAKE_COMMAND}
            -DEXE=$<TARGET_FILE:sim_darksocv>
            -DWD=${_sim}
            -P ${DARKRISCV_CMAKE_DIR}/ExpectPass.cmake
    COMMENT "Run headless DarkSoCV Verilator teaching sim (cwd=sim/)"
    VERBATIM)

  add_test(NAME sim_darksocv
    COMMAND ${CMAKE_COMMAND}
            -DEXE=$<TARGET_FILE:sim_darksocv>
            -DWD=${_sim}
            -P ${DARKRISCV_CMAKE_DIR}/ExpectPass.cmake)

  message(STATUS "DarkriscvSim: wrap sim/verilator (top darksocv, cwd=${_sim})")
endfunction()
