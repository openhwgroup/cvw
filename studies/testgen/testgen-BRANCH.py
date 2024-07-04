#!/usr/bin/env python3
##################################
# testgen-branch.py
#
# ssanghai@hmc.edu 13th Feb 2021
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
def computeExpected(a, b, test):
  if (test == "BEQ"):
    return 0xcccc if a==b else 0xeeee
  elif (test == "BNE"):
    return 0xeeee if a==b else 0xcccc
  elif (test == "BGEU"):
    return 0xcccc if a>=b else 0xeeee
  elif (test == "BLT"):
    if (1<<(xlen-1)) & a:
      a = a -(2**xlen) 
    if (1<<(xlen-1)) & b:
      b = b - (2**xlen)
    return 0xcccc if a<b else 0xeeee
  elif (test == "BLTU"):
    return 0xcccc if a<b else 0xeeee
  elif (test == "BGE"):
    if (1<<(xlen-1)) & a:
      a = a - (2**xlen)
    if (1<<(xlen-1)) & b:
      b = b - (2**xlen)
    return 0xcccc if a>=b else 0xeeee
  else:
    die("bad test name ", test)
  #  exit(1)

def randRegs():
  reg1 = randint(2,31)
  reg2 = randint(2,31)
  if (reg1 == 6 or reg2 == 6 or reg1 == reg2):
    return randRegs()
  else:
      return reg1, reg2

label = 0

def writeVector(a, b, storecmd):
  global testnum 
  global label
  expected = computeExpected(a, b, test)
  expected = expected % 2**xlen # drop carry if necessary
  if (expected < 0): # take twos complement
    expected = 2**xlen + expected
  reg1, reg2 = randRegs()
  lines = "\n# Testcase " + str(testnum) + ":  rs1:x" + str(reg1) + "(" + formatstr.format(a)
  lines = lines + "), rs2:x" + str(reg2) + "(" +formatstr.format(b) + "\n"
  lines = lines + "li x1, MASK_XLEN(0xcccc)\n"
  lines = lines + "li x" + str(reg1) + ", MASK_XLEN(" + formatstr.format(a) + ")\n"
  lines = lines + "li x" + str(reg2) + ", MASK_XLEN(" + formatstr.format(b) + ")\n"
  lines = lines + test + " x" + str(reg1) + ", x" + str(reg2) + ", " + str(label) + "f\n"
  lines = lines + "li x1, MASK_XLEN(0xeeee)\n"
  lines = lines + str(label) + ":\n"
  lines = lines + storecmd + " x1, " + str(wordsize*testnum) + "(x6)\n"
  lines = lines + "RVTEST_IO_ASSERT_GPR_EQ(x7, x1, "+formatstr.format(expected)+")\n"
  f.write(lines)
  if (xlen == 32):
    line = formatrefstr.format(expected)+"\n"
  else:
    line = formatrefstr.format(expected % 2**32)+"\n" + formatrefstr.format(expected >> 32) + "\n"
  r.write(line)
  label += 1
  testnum = testnum+1

##################################
# main body
##################################

# change these to suite your tests
tests = ["BEQ", "BNE", "BLT", "BGE", "BGEU", "BLTU"] 
author = "Shreya Sanghai"
xlens = [32, 64]
numrand = 100

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
    corners = [0, 1, 2, 0xFF, 0x624B3E976C52DD14 % 2**xlen, 2**(xlen-1)-2, 2**(xlen-1)-1, 
            2**(xlen-1), 2**(xlen-1)+1, 0xC365DDEB9173AB42 % 2**xlen, 2**(xlen)-2, 2**(xlen)-1]
    imperaspath = "../../imperas-riscv-tests/riscv-test-suite/rv" + str(xlen) + "i/"
    basename = "WALLY-" + test 
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
    lines = ".fill " + str(testnum) + ", " + str(wordsize) + ", -1\n"
    lines = lines + "\nRV_COMPLIANCE_DATA_END\n" 
    f.write(lines)
    f.close()
    r.close()




