#!/usr/bin/env python3
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
  if (test == "SLTIU"):
    return a < b
  else:
    die("bad test name ", test)
  #  exit(1)

def signExt(b, bits):
  a_str = bin(b)[2::]
  if (a_str[0] == "b"):
    a_str = a_str[1:]

  if (len(a_str) < 12):
    zeroPadding = "0" * (12 - len(a_str))
    a_str = zeroPadding + a_str
  
  
  padding = a_str[0] * (bits - len(a_str))
  print( "b {:x}, sign extended {:s} ".format(b, padding + a_str))
  return int(padding + a_str, 2)



def evaluateTwoComplement(b, bits):
  if (b & (1 << (bits -1))!= 0):
    b = b - (1 << bits)
  return b


def randRegs():
  reg1 = randint(1,31)
  reg3 = randint(1,31) 
  if (reg1 == 6 or reg3 == 6):
    return randRegs()
  else:
      return reg1, reg3

def writeVector(a, b, storecmd):
  global testnum


  
  signExtImm = signExt(b,xlen)
  if signExtImm < 0:
    signExtImm = signExtImm + 2 ** xlen
  expected = computeExpected(a, signExtImm, test)
  # s
  
  expected = expected % 2**xlen # drop carry if necessary
  if (expected < 0): # take twos complement
    expected = 2**xlen + expected



  reg1, reg3 = randRegs()
  lines = "\n# Testcase " + str(testnum) + ":  rs1:x" + str(reg1) + "(" + formatstr.format(a)
  lines = lines + "), imm12:" + "(" +formatstrimm12.format(b) 
  lines = lines + "), result rd:x" + str(reg3) + "(" + formatstr.format(expected) +")\n"
  lines = lines + "li x" + str(reg1) + ", MASK_XLEN(" + formatstr.format(a) + ")\n"
  lines = lines + test + " x" + str(reg3) + ", x" + str(reg1) + ", SEXT_IMM(" + formatstrimm12.format(b) + ")\n"
  # lines = lines + test + " x" + str(reg3) + ", x" + str(reg1) + ", MASK_XLEN(" + formatstr.format(b) + ")\n"
  lines = lines + storecmd + " x" + str(reg3) + ", " + str(wordsize*testnum) + "(x6)\n"
  lines = lines + "RVTEST_IO_ASSERT_GPR_EQ(x7, " +"x" + str(reg3) +", "+formatstr.format(expected)+")\n"
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
tests = ["SLTIU"]
author = "Shriya Nadgauda & Ethan Falicov"
xlens = [32, 64]
numrand = 100


# setup
seed(0) # make tests reproducible

# generate files for each test
for xlen in xlens:
  formatstrlen = str(int(xlen/4))
  formatstr = "0x{:0" + formatstrlen + "x}" # format as xlen-bit hexadecimal number
  formatrefstr = "{:08x}" # format as xlen-bit hexadecimal number with no leading 0x

  formatstrimm12 = "0x{:03x}" # format as 3-bit hexadecimal number
  if (xlen == 32):
    storecmd = "sw"
    wordsize = 4
  else:
    storecmd = "sd"
    wordsize = 8

  for test in tests:
    corners1 = [0, 1, 2, 0xFF, 0x624B3E976C52DD14 % 2**xlen, 2**(xlen-1)-2, 2**(xlen-1)-1, 
            2**(xlen-1), 2**(xlen-1)+1, 0xC365DDEB9173AB42 % 2**xlen, 2**(xlen)-2, 2**(xlen)-1]

    immBitSize = 12
    corners2 = [0, 1, 2, 0xFF, 0x624 % 2**immBitSize, 2**(immBitSize-1)-2, 2**(immBitSize-1)-1, 
            2**(immBitSize-1), 2**(immBitSize-1)+1, 0xC36 % 2**immBitSize, 2**(immBitSize)-2, 2**(immBitSize)-1]

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
    for a in corners1:
      for b in corners2:
        writeVector(a, b, storecmd)
    for i in range(0,numrand):
      a = getrandbits(xlen)
      b = getrandbits(12)
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



