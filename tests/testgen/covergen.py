#!/usr/bin/python3
##################################
# covergen.py
#
# David_Harris@hmc.edu 27 March 2024
#
# Generate directed tests for functional coverage
##################################

##################################
# libraries
##################################
from datetime import datetime
from random import randint 
from random import seed
from random import getrandbits

##################################
# functions
##################################

def writeCovVector(desc, rs1, rs2, rd, rs1val, rs2val, test, storecmd, xlen):
  rdval = randint(0, 2**xlen-1)
  lines = "\n# Testcase " + str(desc) + "\n"
  lines = lines + "li x" + str(rd) + ", MASK_XLEN(" + formatstr.format(rdval) + ")  # initialize rd to a random value that should get changed\n"
  lines = lines + "li x" + str(rs1) + ", MASK_XLEN(" + formatstr.format(rs1val) + ")  # initialize rs1 to a random value \n"
  lines = lines + "li x" + str(rs2) + ", MASK_XLEN(" + formatstr.format(rs2val) + ") # initialize rs2 to a random value\n"
  lines = lines + test + " x" + str(rd) + ", x" + str(rs1) + ", x" + str(rs2) + " # perform operation\n" 
  f.write(lines)

def make_cp_rd(rd, test, storecmd, xlen):
  rs1 = randint(0, 31)
  rs2 = randint(0, 31)
  rs1val = randint(0, 2**xlen-1)
  rs2val = randint(0, 2**xlen-1)
  desc = "cp_rd (Test destination rd = x" + str(rd) + ")"
  writeCovVector(desc, rs1, rs2, rd, rs1val, rs2val, test, storecmd, xlen)

def make_cp_rs1(rs1, test, storecmd, xlen):
  rd = randint(0, 31)
  rs2 = randint(0, 31)
  rs1val = randint(0, 2**xlen-1)
  rs2val = randint(0, 2**xlen-1)
  desc = "cp_rs1 (Test source rs1 = x" + str(rs1) + ")"
  writeCovVector(desc, rs1, rs2, rd, rs1val, rs2val, test, storecmd, xlen)

def make_cp_rs2(rs2, test, storecmd, xlen):
  rd = randint(0, 31)
  rs1 = randint(0, 31)
  rs1val = randint(0, 2**xlen-1)
  rs2val = randint(0, 2**xlen-1)
  desc = "cp_rs2 (Test source rs2 = x" + str(rs2) + ")"
  writeCovVector(desc, rs1, rs2, rd, rs1val, rs2val, test, storecmd, xlen)

def make_cmp_rd_rs1(r, test, storecmd, xlen):
  rd = r
  rs1 = r
  rs2 = randint(0, 31)
  rs1val = randint(0, 2**xlen-1)
  rs2val = randint(0, 2**xlen-1)
  desc = "cmp_rd_rs1 (Test destination rd = source rs1 = x" + str(r) + ")"
  writeCovVector(desc, rs1, rs2, rd, rs1val, rs2val, test, storecmd, xlen)

def make_cmp_rd_rs2(r, test, storecmd, xlen):
  rd = r
  rs1 = randint(0, 31)
  rs2 = r
  rs1val = randint(0, 2**xlen-1)
  rs2val = randint(0, 2**xlen-1)
  desc = "cmp_rd_rs2 (Test destination rd = source rs2 = x" + str(r) + ")"
  writeCovVector(desc, rs1, rs2, rd, rs1val, rs2val, test, storecmd, xlen)

def make_cmp_rd_rs1_rs2(r, test, storecmd, xlen):
  rd = r
  rs1 = r
  rs2 = r
  rs1val = randint(0, 2**xlen-1)
  rs2val = randint(0, 2**xlen-1)
  desc = "cmp_rd_rs1_rs2 (Test destination rd = source rs1 = source rs2 = x" + str(r) + ")"
  writeCovVector(desc, rs1, rs2, rd, rs1val, rs2val, test, storecmd, xlen)

def make_cp_gpr_hazard(test, storecmd, xlen):
  rs1val = randint(0, 2**xlen-1)
  rs2val = randint(0, 2**xlen-1)
  desc = "cp_gpr_hazard"
  writeCovVector(desc, 20, 21, 22, rs1val, rs2val, test, storecmd, xlen)
  lines = test + " x23, x22, x20 # RAW\n" 
  lines = lines + test + " x22, x23, x20 # WAR\n" 
  lines = lines + test + " x22, x21, x20 # WAW\n" 
  f.write(lines)

def make_cp_rs1_maxvals(test, storecmd, xlen):
  for rs1val in [0, 2**(xlen-1), 2**(xlen-1)-1, 2**xlen-1, 1, 2**(xlen-1)+1]:
    rd = randint(1, 31)
    rs1 = randint(0, 31)
    rs2 = randint(0, 31)
    rs2val = randint(0, 2**xlen-1)
    desc = "cp_rs1_maxvals (rs1 = " + str(rs1val) + ")"
    writeCovVector(desc, rs1, rs2, rd, rs1val, rs2val, test, storecmd, xlen)

def make_cp_rs2_maxvals(test, storecmd, xlen):
  for rs2val in [0, 2**(xlen-1), 2**(xlen-1)-1, 2**xlen-1, 1, 2**(xlen-1)+1]:
    rd = randint(1, 31)
    rs1 = randint(0, 31)
    rs2 = randint(0, 31)
    rs1val = randint(0, 2**xlen-1)
    desc = "cp_rs2_maxvals (rs2 = " + str(rs2val) + ")"
    writeCovVector(desc, rs1, rs2, rd, rs1val, rs2val, test, storecmd, xlen)


def writeCovVector(desc, rs1, rs2, rd, rs1val, rs2val, test, storecmd, xlen):
  rdval = randint(0, 2**xlen-1)
  lines = "\n# Testcase " + str(desc) + "\n"
  lines = lines + "li x" + str(rd) + ", MASK_XLEN(" + formatstr.format(rdval) + ")  # initialize rd to a random value that should get changed\n"
  lines = lines + "li x" + str(rs1) + ", MASK_XLEN(" + formatstr.format(rs1val) + ")  # initialize rs1 to a random value \n"
  lines = lines + "li x" + str(rs2) + ", MASK_XLEN(" + formatstr.format(rs2val) + ") # initialize rs2 to a random value\n"
  lines = lines + test + " x" + str(rd) + ", x" + str(rs1) + ", x" + str(rs2) + " # perform operation\n" 
  f.write(lines)


def write_rtype_arith_vectors(test, storecmd, xlen):
  for r in range(32):
    make_cp_rd(r, test, storecmd, xlen)
  for r in range(32):
    make_cp_rs1(r, test, storecmd, xlen)
  for r in range(32):
    make_cp_rs2(r, test, storecmd, xlen)  
  for r in range(32):
    make_cmp_rd_rs2(r, test, storecmd, xlen)
  for r in range(32):
    make_cmp_rd_rs1(r, test, storecmd, xlen)
  for r in range(32):
    make_cmp_rd_rs1_rs2(r, test, storecmd, xlen)
  make_cp_gpr_hazard(test, storecmd, xlen)
  make_cp_rs1_maxvals(test, storecmd, xlen)
  make_cp_rs2_maxvals(test, storecmd, xlen)

##################################
# main body
##################################

# change these to suite your tests
rtests = ["ADD", "SUB", "SLT", "SLTU", "XOR"]
tests = rtests
author = "David_Harris@hmc.edu"
xlens = [64]
numrand = 3

# setup
seed(0) # make tests reproducible

# generate files for each test
for xlen in xlens:
  formatstrlen = str(int(xlen/4))
  formatstr = "0x{:0" + formatstrlen + "x}" # format as xlen-bit hexadecimal number
  formatrefstr = "{:08x}" # format as xlen-bit hexadecimal number with no leading 0x
  if (xlen == 32):
    storecmd = "sw"
    wordsize = 4
  else:
    storecmd = "sd"
    wordsize = 8
  for test in tests:
#    corners = [0, 1, 2, 0xFF, 0x624B3E976C52DD14 % 2**xlen, 2**(xlen-1)-2, 2**(xlen-1)-1, 
#            2**(xlen-1), 2**(xlen-1)+1, 0xC365DDEB9173AB42 % 2**xlen, 2**(xlen)-2, 2**(xlen)-1]
    corners = [0, 1, 2**(xlen)-1]
    pathname = "../wally-riscv-arch-test/riscv-test-suite/rv" + str(xlen) + "i_m/I/"
    basename = "WALLY-COV-" + test 
    fname = pathname + "src/" + basename + ".S"

    # print custom header part
    f = open(fname, "w")
    line = "///////////////////////////////////////////\n"
    f.write(line)
    lines="// "+fname+ "\n// " + author + "\n"
    f.write(lines)
    line ="// Created " + str(datetime.now()) 
    f.write(line)

    # insert generic header
    h = open("covergen_header.S", "r")
    for line in h:  
      f.write(line)

    # print directed and random test vectors
    # Coverage for R-type arithmetic instructions
    if (test not in rtests):
      exit("Error: %s not implemented yet" % test)
    else:
      write_rtype_arith_vectors(test, storecmd, xlen)
      
    # print footer
    line = "\n.EQU NUMTESTS," + str(1) + "\n\n"
    f.write(line)
    h = open("covergen_footer.S", "r")
    for line in h:  
      f.write(line)

    # Finish
#    lines = ".fill " + str(testnum) + ", " + str(wordsize) + ", -1\n"
#    lines = lines + "\nRV_COMPLIANCE_DATA_END\n" 
    f.write(lines)
    f.close()




