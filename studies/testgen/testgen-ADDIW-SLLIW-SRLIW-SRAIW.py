#!/usr/bin/env python3
##################################
# testgen-ADDIW-SLLIW-SRLIW-SRAIW.py
#
# ehedenberg@hmc.edu 4 February 2021
# heavily influenced by Prof Harris Code
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
import sys

##################################
# functions
##################################
def logical_rshift(signed_integer, places):
  unsigned_integer=signed_integer%(1<<32)
  return unsigned_integer >> places

def toSigned12bit(n):
  n=n & 0xfff
  if (n&(1<<11)):
    n=n|0xfffffffffffff000
  return n

def toSigned32bit(n):
  n=n & 0xffffffff
  if (n&(1<<31)):
    n=n|0xffffffff00000000
  return n


def computeExpected(a, b, test):
  if (test == "ADDIW"):
    b=toSigned12bit(b)
    return a + b
  elif (test == "SLLIW"):
    return (a << b)
  elif (test == "SRLIW"):
    return logical_rshift(a, b)
  elif(test == "SRAIW"):
    a= toSigned32bit(a)
    return a >> b
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

def writeVector(a, b, storecmd):
  global testnum
  expected = computeExpected(a, b, test)
  expected = expected % 2**64 # drop carry if necessary
  if (expected < 0): # take twos complement
    expected = 2**64 + expected
    #expected=expected+2^32<<32
  if (expected >= (2**32)):
    expected=expected%(2**32)
  expected=toSigned32bit(expected)
  reg1, reg2, reg3 = randRegs()
  lines = "\n# Testcase " + str(testnum) + ":  rs1:x" + str(reg1) + "(" + formatstr.format(a)
  lines = lines + "), imm:"+formatstr.format(b) 
  lines = lines + ", result rd:x" + str(reg3) + "(" + formatstr.format(expected) +")\n"
  lines = lines + "li x" + str(reg1) + ", MASK_XLEN(" + formatstr.format(a) + ")\n"
  #lines = lines + "li x" + str(reg2) + ", MASK_XLEN(" + formatstr.format(b) + ")\n"
  lines = lines + test + " x" + str(reg3) + ", x" + str(reg1) + ", SEXT_IMM(" + formatstr.format(b) + ")\n"
  lines = lines + storecmd + " x" + str(reg3) + ", " + str(wordsize*testnum) + "(x6)\n"
  lines = lines + "RVTEST_IO_ASSERT_GPR_EQ(x7, x" + str(reg3) +", "+formatstr.format(expected)+")\n"
  #lines = lines + str(b)+"\n"
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
tests = ["ADDIW", "SLLIW", "SRLIW", "SRAIW"]
author = "Eizabeth Hedenberg"
xlens = [64]
shiftlen=5
addlen=12
numrand = 100

# setup
seed(0) # make tests reproducible

# generate files for each test
for xlen in xlens:
  formatstrlen = str(int(xlen/4))
  #formatstrlen6=str(int())
  formatstr = "0x{:0" + formatstrlen + "x}" # format as xlen-bit hexadecimal number
  #formatstr6 = "0x{:0" + "2" + "x}" # format as xlen-bit hexadecimal number
  formatrefstr = "{:08x}" # format as xlen-bit hexadecimal number with no leading 0x
  if (xlen == 32):
    storecmd = "sw"
    wordsize = 4
  else:
    storecmd = "sd"
    wordsize = 8
  for test in tests:
    cornersa = [0, 1, 2, 0xFF, 0x624B3E976C52DD14 % 2**xlen, 2**(xlen-1)-2, 2**(xlen-1)-1, 
            2**(xlen-1), 2**(xlen-1)+1, 0xC365DDEB9173AB42 % 2**xlen, 2**(xlen)-2, 2**(xlen)-1]
            #test both confined to top 32 and not
    cornersshift=[0, 1, 2, 2**(shiftlen)-1, 2**(shiftlen)-2, 0b00101, 0b01110]
    #6 bits: 0, 1, 2, largest, largest -1, largest -2,  21, 46
    cornersadd=[0, 1, 2, 2**(addlen-1), 2**(addlen-1)-1, 2**(addlen-1)-2, 2**(addlen-1)+1, 2**(addlen)-2, 2**(addlen)-1, 0b001010010101, 0b101011101111]
    #12 bit, 0, 1, 2 argest positive, largest -1, largest -2, largest negative number, -2, -1, random
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
    if test=="ADDIW":
      for a in cornersa:
        for b in cornersadd:
          writeVector(a, b, storecmd)
      for i in range(0,numrand):
        a = getrandbits(xlen)
        b = getrandbits(12)
        writeVector(a, b, storecmd)
    else:
      for a in cornersa:
        for b in cornersshift:
          writeVector(a, b, storecmd)
      for i in range(0,numrand):
        a = getrandbits(xlen)
        b = getrandbits(5)
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




