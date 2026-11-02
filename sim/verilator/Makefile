# Copyright (c) 2018, Marcelo Samsoniuk
# Headless Verilator path for the DarkRISCV learning ladder.
# Default Icarus flow in ../Makefile is unchanged.

VERILATOR ?= verilator
TOP       ?= darksocv
VDIR      := obj_dir
VBIN      := $(VDIR)/V$(TOP)
CPP       := tb_verilator.cpp
RTL_F     := rtl.f
MEM       := ../../src/darksocv.mem

# Run from sim/ so $readmemh("../src/darksocv.mem") matches Icarus.

VFLAGS += --cc --exe --build -j 0
VFLAGS += --top-module $(TOP)
VFLAGS += --relative-includes
VFLAGS += -I../../rtl
VFLAGS += --no-timing
VFLAGS += -Wno-fatal
VFLAGS += -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND
VFLAGS += -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM
VFLAGS += -Wno-PINCONNECTEMPTY -Wno-PINMISSING
VFLAGS += -Wno-CASEINCOMPLETE -Wno-CASEX
VFLAGS += -Wno-TIMESCALEMOD -Wno-UNSIGNED -Wno-REALCVT
VFLAGS += -Wno-BLKANDNBLK -Wno-UNOPTFLAT
VFLAGS += -CFLAGS "-O2"
VFLAGS += -Mdir $(VDIR)

ifdef TRACE
VFLAGS += --trace -CFLAGS "-O2 -DVM_TRACE=1"
endif

PLUSARGS ?=

.PHONY: all sim build clean

all: sim

$(MEM):
	$(MAKE) -C ../../src all

build: $(VBIN)

$(VBIN): $(CPP) $(RTL_F) $(wildcard ../../rtl/*.v) $(wildcard ../../rtl/*.vh)
	$(VERILATOR) $(VFLAGS) -f $(RTL_F) $(CPP)

sim: $(VBIN) $(MEM)
	cd .. && ./verilator/$(VBIN) $(PLUSARGS) 2>&1 | tee verilator/last-run.log
	@grep -q "Welcome to DarkRISCV" last-run.log
	@grep -q "SIM DONE" last-run.log
	@grep -q "ALL TESTS PASSED" last-run.log
	@grep -q "verilator_exit=0" last-run.log
	@echo "verilator teaching sim ok."

clean:
	rm -rf $(VDIR) last-run.log darksocv_verilator.vcd
