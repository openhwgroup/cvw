#!/usr/bin/python3

# run_vcs
# David_Harris@hmc.edu 2 July 2024
# Run VCS on a given file, passing appropriate flags
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1


import argparse
import os
import subprocess

# run a Linux command and return the result as a string in a form that VCS can use
def runfindcmd(cmd):
#    print("Executing: " + str(cmd) )
    res = subprocess.check_output(cmd, shell=True)
    res = str(res)
    res = res.replace("\\n", " ")  # replace newline with space
    res = res.replace("\'", "")  # strip off quotation marks
    res = res[1:] # strip off leading b from byte string
    return res

parser = argparse.ArgumentParser()
parser.add_argument("config", help="Configuration file")
parser.add_argument("testsuite", help="Test suite (or none, when running a single ELF file) ")
parser.add_argument("--elffile", "-e", help="ELF file name", default="")
parser.add_argument("--coverage", "-c", help="Code & Functional Coverage", action="store_true")
parser.add_argument("--fcov", "-f", help="Code & Functional Coverage", action="store_true")
parser.add_argument("--args", "-a", help="Optional arguments passed to simulator via $value$plusargs", default="")
parser.add_argument("--lockstep", "-l", help="Run ImperasDV lock, step, and compare.", action="store_true")
# GUI not yet implemented
#parser.add_argument("--gui", "-g", help="Simulate with GUI", action="store_true")
args = parser.parse_args()
print("run_vcs Config=" + args.config + " tests=" + args.testsuite + " elffile=" + args.elffile + " lockstep=" + str(args.lockstep) + " args='" + args.args + "'")

cfgdir = "$WALLY/config"
srcdir = "$WALLY/src"
tbdir = "$WALLY/testbench"
wkdir = "$WALLY/sim/vcs/wkdir/" + args.config + "_" + args.testsuite
covdir = "$WALLY/sim/vcs/cov/" + args.config + "_" + args.testsuite
logdir = "$WALLY/sim/vcs/logs"

os.system("mkdir -p " + wkdir)
os.system("mkdir -p " + covdir)
os.system("mkdir -p " + logdir)

# Find RTL source files
rtlsrc_cmd = "find " + srcdir + ' -name "*.sv" ! -path "' + srcdir + '/generic/mem/rom1p1r_128x64.sv" ! -path "' + srcdir + '/generic/mem/ram2p1r1wbe_128x64.sv" ! -path "' + srcdir + '/generic/mem/rom1p1r_128x32.sv" ! -path "' + srcdir + '/generic/mem/ram2p1r1wbe_2048x64.sv"'
rtlsrc_files = runfindcmd(rtlsrc_cmd)
tbcommon_cmd = 'find ' + tbdir+'/common -name "*.sv" ! -path "' + tbdir+'/common/wallyTracer.sv"'
tbcommon_files = runfindcmd(tbcommon_cmd)
RTL_FILES = tbdir+'/testbench.sv ' + str(rtlsrc_files) + ' '  + str(tbcommon_files)

# Include directories
INCLUDE_PATH="+incdir+" + cfgdir + "/" + args.config + " +incdir+" + cfgdir + "/deriv/" + args.config + " +incdir+" + cfgdir + "/shared +incdir+$WALLY/tests +incdir+" + tbdir + " +incdir+" + srcdir

# lockstep mode
if (args.lockstep):
    LOCKSTEP_OPTIONS = " +define+USE_IMPERAS_DV +incdir+$IMPERAS_HOME/ImpPublic/include/host  +incdir+$IMPERAS_HOME/ImpProprietary/include/host  $IMPERAS_HOME/ImpPublic/source/host/rvvi/*.sv $IMPERAS_HOME/ImpProprietary/source/host/idv/*.sv " + tbdir + "/common/wallyTracer.sv"
    LOCKSTEP_SIMV = "-sv_lib $IMPERAS_HOME/lib/Linux64/ImperasLib/imperas.com/verification/riscv/1.0/model"
else:
    LOCKSTEP_OPTIONS = ""
    LOCKSTEP_SIMV = ""

# coverage mode
if (args.coverage):
    COV_OPTIONS = "-cm line+cond+branch+fsm+tgl -cm_log " + wkdir + "/coverage.log -cm_dir " + wkdir + "/coverage"
else:
    COV_OPTIONS = ""

# Simulation commands
OUTPUT="sim_out"
VCS_CMD="vcs +lint=all,noGCWM,noUI,noSVA-UA,noIDTS,noNS,noULCO,noCAWM-L,noWMIA-L,noSV-PIU,noSTASKW_CO,noSTASKW_CO1,noSTASKW_RMCOF -suppress +warn -sverilog +vc -Mupdate -line -full64 -lca -ntb_opts sensitive_dyn " + INCLUDE_PATH # Disabled Debug flags; add them back for a GUI mode -debug_access+all+reverse  -kdb +vcs+vcdpluson 
VCS = VCS_CMD + " -Mdir=" + wkdir + " " + srcdir + "/cvw.sv " + LOCKSTEP_OPTIONS + " " + COV_OPTIONS + " " + RTL_FILES + " -o " + wkdir + "/" + OUTPUT + " -work " + wkdir + " -Mlib " + wkdir + " -l " + logdir + "/" + args.config + "_" + args.testsuite + ".log"
SIMV_CMD= wkdir + "/" + OUTPUT + " +TEST=" + args.testsuite + " " + args.elffile + " " + args.args + " -no_save " + LOCKSTEP_SIMV 

# Run simulation
print("Executing: " + str(VCS) )
subprocess.run(VCS, shell=True)
subprocess.run(SIMV_CMD, shell=True)
if (args.coverage):
    COV_RUN = "urg -dir " + wkdir + "/coverage.vdb -format text -report IndividualCovReport/" + args.config + "_" + args.testsuite
    subprocess.run(COV_RUN, shell=True)

