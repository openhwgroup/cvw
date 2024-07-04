#!/usr/bin/env python3
##################################
# testgen-SLL-SRL-SRA.py
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
  b = b % xlen
  if (test == "SLL"):
    return a << b
  elif (test == "SRL"):
    return a >> b
  elif (test == "SRA"):
    return asigned >> b
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
tests = ["SLL", "SRL", "SRA"]
author = "David_Harris@hmc.edu"
xlens = [32, 64]
numrand = 48

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
    if (xlen == 32):
        shamt = [0, 1, 2, 3, 4, 8, 15, 16, 29, 30, 31]
    else:
        shamt = [0, 1, 3, 8, 15, 16, 29, 31, 32, 47, 48, 62, 63]

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
      for b in shamt:
        writeVector(a, b, storecmd, xlen)
    for i in range(0,numrand):
      a = getrandbits(xlen)
      b = getrandbits(xlen)
      writeVector(a, b, storecmd, xlen)


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




