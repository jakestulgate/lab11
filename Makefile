export PATH := /home/shay/a/ece270/bin:$(PATH)
export LD_LIBRARY_PATH := /home/shay/a/ece270/lib:$(LD_LIBRARY_PATH)

YOSYS=yosys
NEXTPNR=nextpnr-ice40
SHELL=bash

PROJ	= lab11
PINMAP 	= pinmap.pcf
TCLPREF = addwave.gtkw
SRC	    = top.sv
ICE   	= ice40hx8k.sv
CHK 	= check.bin
DEM 	= demo.bin
JSON    = ll.json
SUP     = support/moddefs.sv
UART	= uart/uart.v uart/uart_tx.v uart/uart_rx.v
FILES   = $(ICE) $(SRC) $(UART)
TRACE	= $(PROJ).vcd
BUILD   = ./build

DEVICE  = 8k
TIMEDEV = hx8k
FOOTPRINT = ct256

all: cram

#########################
# Flash to FPGA
$(BUILD)/$(PROJ).json : $(ICE) $(SRC) $(PINMAP) Makefile
	# lint with Verilator
	verilator --lint-only --top-module top $(SRC) $(SUP)
	# if build folder doesn't exist, create it
	mkdir -p $(BUILD)
	# synthesize using Yosys
	$(YOSYS) -p "read_json $(JSON); read_verilog -sv -noblackbox $(FILES); synth_ice40 -top ice40hx8k -json $(BUILD)/$(PROJ).json"

$(BUILD)/$(PROJ).asc : $(BUILD)/$(PROJ).json
	# Place and route using nextpnr
	$(NEXTPNR) --hx8k --package ct256 --pcf $(PINMAP) --asc $(BUILD)/$(PROJ).asc --json $(BUILD)/$(PROJ).json 2> >(sed -e 's/^.* 0 errors$$//' -e '/^Info:/d' -e '/^[ ]*$$/d' 1>&2)

$(BUILD)/$(PROJ).bin : $(BUILD)/$(PROJ).asc
	# Convert to bitstream using IcePack
	icepack $(BUILD)/$(PROJ).asc $(BUILD)/$(PROJ).bin

#########################
# Verification Suite
VFLAGS = --build --cc --exe --trace-fst --Mdir build

verify_ll_alu: top.sv tb.cpp
	verilator --lint-only -Wno-MULTITOP top.sv
	@echo ========================================
	@echo Compiling and verifying ll_alu...
	@rm -rf build
	verilator $(VFLAGS) --top-module ll_alu -CFLAGS -DLL_ALU top.sv tb.cpp 1>/dev/null
	./build/Vll_alu

verify_ll_memory: top.sv tb.cpp
	verilator --lint-only -Wno-MULTITOP top.sv
	@echo ========================================
	@echo Compiling and verifying ll_memory...
	@rm -rf build
	verilator $(VFLAGS) --top-module ll_memory -CFLAGS -DLL_MEMORY top.sv tb.cpp 1>/dev/null
	./build/Vll_memory

verify_ll_control: top.sv tb.cpp
	verilator --lint-only -Wno-MULTITOP top.sv
	@echo ========================================
	@echo Compiling and verifying ll_control...
	@rm -rf build
	verilator $(VFLAGS) --top-module ll_control -CFLAGS -DLL_CONTROL top.sv tb.cpp 1>/dev/null
	./build/Vll_control
	
#########################
# ice40 Specific Targets
check: $(CHK)
	iceprog -S $(CHK)
	
demo:  $(DEM)
	iceprog -S $(DEM)

flash: $(BUILD)/$(PROJ).bin
	iceprog $(BUILD)/$(PROJ).bin

cram: $(BUILD)/$(PROJ).bin
	iceprog -S $(BUILD)/$(PROJ).bin

time: $(BUILD)/$(PROJ).asc
	icetime -p $(PINMAP) -P $(FOOTPRINT) -d $(TIMEDEV) $<

#########################
# Clean Up
clean:
	rm -rf build/ *.fst verilog.log