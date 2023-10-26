.PHONY: all clean rclean


# File Constants
RTL = ./rtl/
VERIF = ./verif/
LSU = $(RTL)lsu.sv
LSU_TB_FILE = tb_lsu
LSU_TB = $(VERIF)$(LSU_TB_FILE).sv
RAM_PARAMS = ../mem/params/ram_params.sv
RAM = ../mem/rtl/ram.sv
MEM = ../mem/rtl/memblock.sv
LSU_TB_OUTPUT = $(OUT_DIR)$(XSIM_DIR)work/$(LSU_TB_FILE).sdb
XELAB_OUTPUT = $(OUT_DIR)$(XSIM_DIR)work.$(LSU_TB_FILE)/xsim.dbg
PWD = $(shell pwd)/
VCD = $(LSU_TB_FILE).vcd

# Directory Constants
OUT_DIR = ./OUT_DIRFiles/
XSIM_DIR = ./xsim.dir/

# Executable Constants (VLOG)
VLOG_CC = xvlog
VLOG_CC_OPTIONS = --sv -nolog
VLOG_FILE = xvlog.pb
# Executable Constants (ELAB)
ELAB_CC = xelab
ELAB_CC_OPTIONS = -debug typical
# Executable Constants (SIM)
SIM_CC = xsim
SIM_CC_OPTIONS = -R 

all: $(VCD)

$(VCD): $(LSU) $(LSU_TB) $(RAM MEM)
	# Building the xsim.dir, Directory
	$(VLOG_CC) $(VLOG_CC_OPTIONS) $(LSU) $(LSU_TB) $(RAM_PARAMS) $(RAM) $(MEM)

	# Moving the files into a temporary directory
	mkdir -p $(OUT_DIR)
	mv $(XSIM_DIR) $(OUT_DIR)$(XSIM_DIR)
	mv $(VLOG_FILE) $(OUT_DIR)$(VLOG_FILE)

	cd $(PWD)$(OUT_DIR) && $(ELAB_CC) $(ELAB_CC_OPTIONS) $(LSU_TB_FILE)

	cd $(PWD)$(OUT_DIR) && $(SIM_CC) $(LSU_TB_FILE) $(SIM_CC_OPTIONS) 

clean:
	rm -rf $(OUT_DIR)
	rm -rf $(XSIM_DIR)
	rm -rf *.pb *.log *.jou *.wdb

rclean: clean
	rm -rf *.vcd
