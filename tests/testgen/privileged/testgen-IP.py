#!/usr/bin/env python3
##################################
# testgen-IE.py
#
# ushakya@hmc.edu 31 March 2021
# Modified: 4 April 2021
#
# Generate directed and random test vectors for RISC-V Design Validation.
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

def getInteruptEnableValues():
  if test == "timerM":
    mstatusE = 0x8
    mieE = 0x80
  elif test == "timerS":
    mstatusE = 0x2
    mieE = 0x20
  elif test == "timerU":
    mstatusE = 0x1
    mieE = 0x10
  elif test == "softwareM":
    mstatusE = 0x8
    mieE = 0x8
  elif test == "softwareS":
    mstatusE = 0x2
    mieE = 0x2
  elif test == "softwareU":
    mstatusE = 0x1
    mieE = 0x1
  elif test == "externalM":
    mstatusE = 0x8
    mieE = 0x800
  elif test == "externalS":
    mstatusE = 0x2
    mieE = 0x200
  elif test == "externalU":
    mstatusE = 0x1
    mieE = 0x100
  return [mstatusE, mieE]

def getMcause():
  b = 1 << (xlen-1)
  if test == "timerM":
    b = b + 0x7
  elif test == "timerS":
    b = b + 0x5
  elif test == "timerU":
    b = b + 0x4
  elif test == "softwareM":
    b = b + 0x3
  elif test == "softwareS":
    b = b + 0x1
  elif test == "softwareU":
    b = b
  elif test == "externalM":
    b = b + 0xB
  elif test == "externalS":
    b = b + 0x9
  elif test == "externalU":
    b = b + 0x8
  return b

# MIP is implicitly tested in the MIE tests
# these tests are to test that when mtimecmp < mtime
# MTIP bit is high in MIP
def writeVectors(a, xlen, storecmd):
  global testnum

  [reg2, reg3] = [2, 3]
  [reg5, reg8] = [5, 8]
  [reg10, reg11, reg12] = [10, 11, 12]
  [reg13, reg14, reg15] = [13, 14, 15]

  lines = f"\n# Testcase {testnum}: {test} Interupt\n"
  
  # mcause code
  expected = 0x80

  [mstatusE, mieE] = getInteruptEnableValues()
  # ensure interupt enable bit in mie is low
  lines += "li x" + str(reg8) + ", MASK_XLEN(" + formatstr.format(mieE) + ")\n"
  lines += "csrrc x0, mie, x" + str(reg8) + "\n"

  # set interupt enable bit in mstatus
  lines += "li x" + str(reg3) + ", MASK_XLEN(" + formatstr.format(mstatusE) + ")\n"
  lines += "csrrs x0, mstatus, x" + str(reg3) + "\n"
  
  # cause timer interupt
  if test == "timerM":
    
    # load MTIMECMP register address
    lines += "la x" + str(reg2) + ", 0x2004000\n"

    # to be stored in MTIMECMP
    lines += "li x" + str(reg10) + ", MASK_XLEN(0)\n"

    # save old value of mtimecmp and then set mtimecmp to zero
    if xlens == 64:
      lines += "lw x" + str(reg11) + ", 0(x" + str(reg2) + ")\n"
      lines += str(storecmd) + " x" + str(reg10) + ",  0(x" + str(reg2) + ")\n"

    elif xlen == 32:
      lines += "lw x" + str(reg11) + ", 0(x" + str(reg2) + ")\n"
      lines += str(storecmd) + " x" + str(reg10) + ",  0(x" + str(reg2) + ")\n"
      lines += str(storecmd) + " x" + str(reg10) + ",  4(x" + str(reg2) + ")\n"

  lines += "csrrs " + " x" + str(reg13) + ", mip, x0\n"

  lines += storecmd + " x" + str(reg13) + ", " + str(wordsize*testnum) + "(x6)\n"
  lines += "RVTEST_IO_ASSERT_GPR_EQ(x7, x" + str(reg13) +", "+formatstr.format(expected)+")\n"
  f.write(lines)
  if (xlen == 32):
    line = formatrefstr.format(expected)+"\n"
  else:
    line = formatrefstr.format(expected % 2**32)+"\n" + formatrefstr.format(expected >> 32) + "\n"
  r.write(line)
  testnum = testnum+1

##################################
# main body
##################################

# change these to suite your tests
tests = ["timerM"] #, "softwareM"]
author = "ushakya@hmc.edu"
xlens = [64, 32]
numrand = 100;

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
  
  imperaspath = "../../../imperas-riscv-tests/riscv-test-suite/rv" + str(xlen) + "p/"
  basename = "WALLY-IP"
  fname = imperaspath + "src/" + basename + ".S"
  refname = imperaspath + "references/" + basename + ".reference_output"
  testnum = 0

  # print custom header part
  f = open(fname, "w")
  r = open(refname, "w")
  line = "///////////////////////////////////////////\n"
  f.write(line)
  lines="// "+fname+ "\n// " + author + "\n"
  f.write(lines)
  line ="// Created " + str(datetime.now()) 
  f.write(line)

  # insert generic header
  h = open("../testgen_header.S", "r")
  for line in h:  
    f.write(line)
  
  for test in tests:
    # print directed and random test vectors
    for i in range(0,numrand):
      a = getrandbits(xlen)
      writeVectors(a, xlen, storecmd)

  f.write(lines)

  # print footer
  h = open("../testgen_footer.S", "r")
  for line in h:  
    f.write(line)

  # Finish
  lines = ".fill " + str(testnum) + ", " + str(wordsize) + ", -1\n"
  lines = lines + "\nRV_COMPLIANCE_DATA_END\n" 
  f.write(lines)

  f.close()
  r.close()
