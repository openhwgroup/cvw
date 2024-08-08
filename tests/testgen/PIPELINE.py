#!/usr/bin/env python3
##################################
# PIPELINE.py
#
# David_Harris@hmc.edu 27 October 2021
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

def twoscomp(a):
  amsb = a >> (xlen-1)
  alsbs = ((1 << (xlen-1)) - 1) & a
  if (amsb):
      asigned = a - (1<<xlen)
  else:
      asigned = a
  #print("a: " + str(a) + " amsb: "+str(amsb)+ " alsbs: " + str(alsbs) + " asigned: "+str(asigned))
  return asigned

def computeExpected(a, b, test, xlen):
  asigned = twoscomp(a)
  bsigned = twoscomp(b)

  if (test == "ADD"):
    return a + b
  elif (test == "SUB"):
    return a - b
  elif (test == "SLT"):
    return asigned < bsigned
  elif (test == "SLTU"):
    return a < b
  elif (test == "XOR"):
    return a ^ b
  elif (test == "OR"):
    return a | b
  elif (test == "AND"):
    return a & b
  else:
    die("bad test name ", test)
  #  exit(1)

def randRegs():
  reg1 = randint(1,31)
  reg2 = randint(1,31)
  reg3 = randint(1,31) 
  if (reg1 == 6 or reg2 == 6 or reg3 == 6 or reg1 == reg2):
    return randRegs()
  else:
      return reg1, reg2, reg3

def writeVector(a, b, storecmd, xlen):
  global testnum
  expected = computeExpected(a, b, test, xlen)
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
  lines = lines + storecmd + " x" + str(reg3) + ", " + str(wordsize*testnum) + "(x6)\n"
  lines = lines + "RVTEST_IO_ASSERT_GPR_EQ(x7, " + str(reg3) +", "+formatstr.format(expected)+")\n"
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
instrs = ["ADD"] # "SUB", "XOR", "OR", "AND", "SLT", "SLTU", ]
author = "David_Harris@hmc.edu"
xlens = [32, 64]
numrand = 1000

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
  pathname = "../wally-riscv-arch-test/riscv-test-suite/rv" + str(xlen) + "i_m/I/"
  fname = pathname + "src/PIPELINE.S"
  testnum = 0

  # print custom header part
  f = open(fname, "w")
#  r = open(refname, "w")
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

  maxreg = 5
  for i in range(numrand):
    instr = instrs[randint(0,len(instrs)-1)]
    reg1 = randint(0,maxreg)
    reg2 = randint(1,maxreg)
    reg3 = randint(1,maxreg)
    line = instr + " x" +str(reg3) + ", x" + str(reg1) + ", x" + str(reg2) + "\n"
    f.write(line)

  for i in range(1,maxreg+1):
    line = storecmd + " x" + str(i) + ", " + str(wordsize*(i-1)) + "(x8)\n"
    f.write(line)

  # print directed and random test vectors
  # for a in corners:
  #   for b in corners:
  #     writeVector(a, b, storecmd, xlen)
  # for i in range(0,numrand):
  #   a = getrandbits(xlen)
  #   b = getrandbits(xlen)
  #   writeVector(a, b, storecmd, xlen)


  # print footer
  h = open("testgen_footer.S", "r")
  for line in h:  
    f.write(line)

  # Finish
#  lines = ".fill " + str(testnum) + ", " + str(wordsize) + ", -1\n"
#  lines = lines + "\nRV_COMPLIANCE_DATA_END\n" 
  f.write(lines)
  f.close()
#  r.close()




