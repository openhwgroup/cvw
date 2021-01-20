#!/usr/bin/python3
##################################
# testgen-ADD-SUB.py
#
# David_Harris@hmc.edu 19 January 2021
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
  if (test == "ADD"):
    return a + b
  elif (test == "SUB"):
    return a - b
  else:
    die("bad test name ", test)
  #  exit(1)

def randRegs():
  reg1 = randint(1,32)
  reg2 = randint(1,32)
  reg3 = randint(1,32) 
  if (reg1 == 6 or reg2 == 6 or reg3 == 6 or reg1 == reg2):
    return randRegs()
  else:
      return reg1, reg2, reg3

def writeVector(a,b):
  global testnum
  expected = computeExpected(a, b, test)
  expected = expected % 2**xlen # drop carry if necessary
  if (expected < 0): # take twos complement
    expected = 2**xlen + expected
  reg1, reg2, reg3 = randRegs()
  lines = "\n# Testcase " + str(testnum) + ":  rs1:x" + str(reg1) + "(" + formatstr.format(a)
  lines = lines + "), rs2:x" + str(reg2) + "(" +formatstr.format(b) 
  lines = lines + "), result rd:x" + str(reg3) + "(" + formatstr.format(expected) +")\n"
  lines = lines + "li x" + str(reg1) + ", MASK_XLEN(" + formatstr.format(a) + ")\n"
  lines = lines + "li x" + str(reg2) + ", MASK_XLEN(" + formatstr.format(b) + ")\n"
  lines = lines + test + " x" + str(reg3) + ", x" + str(reg1) + ", x" + str(reg2) + "\n"
  lines = lines + "sd x" + str(reg3) + ", " + str(8*testnum) + "(x6)\n"
  lines = lines + "RVTEST_IO_ASSERT_GPR_EQ(x7, " + str(reg3) +", "+formatstr.format(expected)+")\n"
  f.write(lines)
  line = formatstr.format(expected)+"\n"
  r.write(line)
  testnum = testnum+1

##################################
# main body
##################################

# change these to suite your tests
tests = ["ADD", "SUB"]
author = "David_Harris@hmc.edu & Katherine Parry"
xlens = [32, 64]
numrand = 100;

# setup
seed(0) # make tests reproducible

# generate files for each test
for xlen in xlens:
  formatstrlen = str(int(xlen/4))
  formatstr = "0x{:0" + formatstrlen + "x}" # format as xlen-bit hexadecimal number
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
        writeVector(a, b)
    for i in range(0,numrand):
      a = getrandbits(xlen)
      b = getrandbits(xlen)
      writeVector(a, b)


    # print footer
    h = open("testgen_footer.S", "r")
    for line in h:  
      f.write(line)

    # Finish
    line = ".fill " + str(testnum) + ", 8, -1\n"
    f.write(line)
    f.close()
    r.close()




