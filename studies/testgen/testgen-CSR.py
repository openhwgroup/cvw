#!/usr/bin/env python3
##################################
# testgen-ADD-SUB.py
#
# ushakya@hmc.edu & dottolia@hmc.edu 14 Feb 2021
# Modified: ushakya@hmc.edu 21 April 2021
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

def randRegs():
  reg1 = randint(1,31)
  reg2 = randint(1,31)
  reg3 = randint(1,31)
  if (reg1 == 6 or reg2 == 6 or reg3 == 6 or reg1 == reg2):
    return randRegs()
  else:
      return reg1, reg2, reg3

def writeVector(a, b, storecmd):
  global testnum
  csr = "mscratch"

  reg1, reg2, reg3 = randRegs()
  lines = "\n# Testcase " + str(testnum) + ":  " + csr + "\n"
  lines = lines + "li x" + str(reg1) + ", MASK_XLEN(" + formatstr.format(a) + ")\n"
  lines = lines + "li x" + str(reg2) + ", MASK_XLEN(0)\n"

  # Page 6 of unpriviledged spec
  # For both CSRRS and CSRRC, if rs1=x0, then the instruction will not write to the CSR at all, and so shall not cause any of the side effects

  expected = a

  if test == "csrrw":
    if testnum == 0:
      # this is a corner case (reading and writing same register)
      expected = 4
      lines += "li x" + str(reg2) + ", MASK_XLEN(" + formatstr.format(0x8) + ")\n"
      lines += "la x" + str(reg1) + ", MASK_XLEN(" + formatstr.format(0x4) + ")\n"
      lines += "csrrw x" + str(reg3) + ", mtvec, x" + str(reg1) + "\n"
      lines += test +  " x" + str(reg2) + ", mtvec, x" + str(reg2) + "\n"
      lines += "csrrw x0, mtvec, x" + str(reg3) + "\n"
    else:
      lines += test + " x" + str(reg2) + ", " + csr + ", x" + str(reg1) + "\n"
      lines += test + " x" + str(reg2) + ", " + csr + ", x" + str(reg1) + "\n"

  elif test == "csrrs": # at some point, try writing a non-zero value first
    lines += "csrrw x0, " + csr + ", x0\n" # set csr to 0

    lines += test + " x" + str(reg2) + ", " + csr + ", x" + str(reg1) + "\n"
    lines += test + " x" + str(reg2) + ", " + csr + ", x" + str(reg1) + "\n"
  elif test == "csrrc": # at some point, try writing a non-one value first
    allOnes = "0xFFFFFFFF" if xlen == 32 else "0xFFFFFFFFFFFFFFFF"

    lines += "li x" + str(reg1) + ", MASK_XLEN(" + allOnes + ")\n"
    lines += "csrrw x0, " + csr + ", x" + str(reg1) + "\n" # set csr to all ones

    lines += "li x" + str(reg1) + ", MASK_XLEN(" + formatstr.format(a) + ")\n"

    lines += test + " x" + str(reg2) + ", " + csr + ", x" + str(reg1) + "\n"
    lines += test + " x" + str(reg2) + ", " + csr + ", x" + str(reg1) + "\n"

    expected = a ^ 0xFFFFFFFF if xlen == 32 else a ^ 0xFFFFFFFFFFFFFFFF
  elif test == "csrrwi":
    a = a & 0x1F # imm is only 5 bits

    lines += test + " x" + str(reg2) + ", " + csr + ", " + str(a) + "\n"
    lines += test + " x" + str(reg2) + ", " + csr + ", " + str(a) + "\n"

    expected = a
  elif test == "csrrsi": # at some point, try writing a non-zero value first
    a = a & 0x1F

    lines += "csrrw x0, " + csr + ", x0\n" # set csr to 0

    lines += test + " x" + str(reg2) + ", " + csr + ", " + str(a) + "\n"
    lines += test + " x" + str(reg2) + ", " + csr + ", " + str(a) + "\n"

    expected = a
  elif test == "csrrci": # at some point, try writing a non-one value first
    a = a & 0x1F
    allOnes = "0xFFFFFFFF" if xlen == 32 else "0xFFFFFFFFFFFFFFFF"

    lines += "li x" + str(reg1) + ", MASK_XLEN(" + allOnes + ")\n"
    lines += "csrrw x0, " + csr + ", x" + str(reg1) + "\n" # set csr to all ones

    lines += test + " x" + str(reg2) + ", " + csr + ", " + str(a) + "\n"
    lines += test + " x" + str(reg2) + ", " + csr + ", " + str(a) + "\n"

    expected = a ^ 0xFFFFFFFF if xlen == 32 else a ^ 0xFFFFFFFFFFFFFFFF


  lines += storecmd + " x" + str(reg2) + ", " + str(wordsize*testnum) + "(x6)\n"
  lines += "RVTEST_IO_ASSERT_GPR_EQ(x7, " + str(reg2) +", "+formatstr.format(expected)+")\n"
  f.write(lines)
  if (xlen == 32):
    line = formatrefstr.format(expected)+"\n"
  else:
    line = formatrefstr.format(expected % 2**32)+"\n" + formatrefstr.format(expected >> 32) + "\n"
  r.write(line)
  testnum = testnum+1

def writeSpec(a, storecmd):
  global testnum
  csr = "mscratch"
  reg1 = 3
  reg2 = 3

  lines = "\n# Testcase " + str(testnum) + ":  " + csr + "\n"
  lines = lines + "li x" + str(reg1) + ", MASK_XLEN(" + formatstr.format(a) + ")\n"
  expected = a

  lines += test + " x" + str(reg2) + ", " + csr + ", x" + str(reg1) + "\n"
  lines += test + " x" + str(reg2) + ", " + csr + ", x" + str(reg1) + "\n"

  lines += storecmd + " x" + str(reg2) + ", " + str(wordsize*testnum) + "(x6)\n"
  lines += "RVTEST_IO_ASSERT_GPR_EQ(x7, " + str(reg2) +", "+formatstr.format(expected)+")\n"
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
# csrrw, csrrs, csrrc, csrrwi, csrrsi, csrrci
tests = ["csrrw", "csrrs", "csrrc", "csrrwi", "csrrsi", "csrrci"]
author = "ushakya@hmc.edu & dottolia@hmc.edu"
xlens = [32, 64]
numrand = 60;

# setup
seed(0xC365DDEB9173AB42) # make tests reproducible

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
    corners = [
      0, 1, 2, 0x1E, 0x1F, 0xFF,
      0x624B3E976C52DD14 % 2**xlen, 2**(xlen-1)-2, 2**(xlen-1)-1, 
      2**(xlen-1), 2**(xlen-1)+1, 0xC365DDEB9173AB42 % 2**xlen, 2**(xlen)-2, 2**(xlen)-1
    ]
    imperaspath = "../../imperas-riscv-tests/riscv-test-suite/rv" + str(xlen) + "i/"
    basename = "WALLY-" + test.upper() 
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
    h = open("testgen_header.S", "r")
    for line in h:  
      f.write(line)

    # print directed and random test vectors
    # test that reading and writing from same register work
    if test == "csrrw":
      a = getrandbits(xlen)
      #writeSpec(a, storecmd)
    for a in corners:
      for b in corners:
        writeVector(a, b, storecmd)
    for i in range(0,numrand):
      a = getrandbits(xlen)
      b = getrandbits(xlen)
      writeVector(a, b, storecmd)


    # print footer
    h = open("testgen_footer.S", "r")
    for line in h:  
      f.write(line)

    # Finish
    lines = ".fill " + str(testnum) + ", " + str(wordsize) + ", -4\n"
    lines = lines + "\nRV_COMPLIANCE_DATA_END\n" 
    f.write(lines)
    f.close()
    r.close()




