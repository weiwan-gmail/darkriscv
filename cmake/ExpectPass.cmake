# Run the headless DarkSoCV Verilator binary from sim/ so
# $readmemh("../src/darksocv.mem") matches Icarus / make test_verilator.
# Succeeds only when the proven UART/C++ PASS markers are present.
#
#   cmake -DEXE=/path/to/sim_darksocv -DWD=/path/to/sim -P cmake/ExpectPass.cmake

if(NOT EXE)
  message(FATAL_ERROR "ExpectPass.cmake requires -DEXE=<path>")
endif()
if(NOT WD)
  message(FATAL_ERROR "ExpectPass.cmake requires -DWD=<sim working directory>")
endif()
if(NOT EXISTS "${EXE}")
  message(FATAL_ERROR "ExpectPass.cmake: EXE not found: ${EXE}")
endif()
if(NOT IS_DIRECTORY "${WD}")
  message(FATAL_ERROR "ExpectPass.cmake: WD not a directory: ${WD}")
endif()

set(_mem "${WD}/../src/darksocv.mem")
if(NOT EXISTS "${_mem}")
  message(FATAL_ERROR
    "ExpectPass.cmake: firmware missing (${_mem}). Run: make -C src all")
endif()

execute_process(
  COMMAND "${EXE}"
  WORKING_DIRECTORY "${WD}"
  RESULT_VARIABLE rc
  OUTPUT_VARIABLE out
  ERROR_VARIABLE err
  ECHO_OUTPUT_VARIABLE
  ECHO_ERROR_VARIABLE
)
set(_all "${out}\n${err}")

if(NOT rc EQUAL 0)
  message(FATAL_ERROR "DarkSoCV sim exited ${rc} (expected 0)")
endif()

foreach(_marker
    "Welcome to DarkRISCV"
    "SIM DONE"
    "ALL TESTS PASSED"
    "verilator_exit=0")
  if(NOT _all MATCHES "${_marker}")
    message(FATAL_ERROR
      "DarkSoCV sim missing PASS marker '${_marker}' (same checks as sim/verilator/Makefile)")
  endif()
endforeach()

message(STATUS "DarkSoCV Verilator teaching sim PASS")
