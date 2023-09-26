.PHONY: all clean rclean


# File Constants
RTL = ./rtl/
VERIF = ./verif/
LSU = $(RTL)lsu.sv
LSU_TB_FILE = tb_lsu
LSU_TB = $(VERIF)$(LSU_TB_FILE).sv
RAM = ../IP_RAM/rtl/ram.sv
MEM = ../IP_RAM/rtl/memblock.sv
LSU_TB_OUTPUT = $(TMP)$(XSIM_DIR)work/$(LSU_TB_FILE).sdb
XELAB_OUTPUT = $(TMP)$(XSIM_DIR)work.$(LSU_TB_FILE)/xsim.dbg
PWD = $(shell pwd)/
VCD = $(LSU_TB_FILE).vcd

# Directory Constants
TMP = ./TmpFiles/
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

$(LSU_TB_OUTPUT): $(LSU) $(LSU_TB) $(RAM MEM)
	# Building the xsim.dir, Directory
	$(VLOG_CC) $(VLOG_CC_OPTIONS) $(LSU) $(LSU_TB) $(RAM) $(MEM)

	# Moving the files into a temporary directory
	mkdir -p $(TMP)
	mv $(XSIM_DIR) $(TMP)$(XSIM_DIR)
	mv $(VLOG_FILE) $(TMP)$(VLOG_FILE)

$(XELAB_OUTPUT): $(LSU_TB_OUTPUT)
	cd $(PWD)$(TMP) && $(ELAB_CC) $(ELAB_CC_OPTIONS) $(LSU_TB_FILE)

$(VCD): $(XELAB_OUTPUT)
	cd $(PWD)$(TMP) && $(SIM_CC) $(LSU_TB_FILE) $(SIM_CC_OPTIONS) 
	mv $(TMP)$(VCD) ./$(VCD)

clean:
	rm -rf $(TMP)
	rm -rf $(XSIM_DIR)
	rm -rf *.pb *.log *.jou *.wdb

rclean: clean
	rm -rf *.vcd
