#!/usr/bin/python3
##################################
# testgen-JAL.py
#
# Ben Bracker (bbracker@hmc.edu) 19 January 2021
# Based on testgen-ADD-SUB.py by David Harris
#
# Generate directed and random test vectors for RISC-V Design Validation.
##################################

##################################
# libraries
##################################
from datetime import datetime
from random import randint
from random import choice
from random import seed
from random import getrandbits
from copy import deepcopy

##################################
# functions
##################################

def InitTestGroup():
  global TestGroup,TestGroupSizes,AllRegs,UnusedRegs,StoreAdrReg
  TestGroup += 1
  TestGroupSizes.append(0)
  UnusedRegs = deepcopy(AllRegs)
  oldStoreAdrReg = StoreAdrReg
  while ((StoreAdrReg == oldStoreAdrReg) or (StoreAdrReg == 0) or (StoreAdrReg == 31)):
    StoreAdrReg = choice(UnusedRegs)
  UnusedRegs.remove(StoreAdrReg)
  f.write("\n    # ---------------------------------------------------------------------------------------------\n")
  f.write("    # new register for address of test results\n")
  addInst("    la x"+str(StoreAdrReg)+", test_1_res\n")
  f.write("    # ---------------------------------------------------------------------------------------------\n")

def registerSelect():
  # ensures that rd experiences all possible registers
  # *** does not yet ensure that rs experiences all possible registers
  # ensures that at least once rd = rs
  global UnusedRegs
  if len(UnusedRegs)==0: 
    InitTestGroup()
  rd = choice(UnusedRegs)
  rs = choice(UnusedRegs)
  UnusedRegs.remove(rd)
  OtherRegs = deepcopy(AllRegs)
  OtherRegs.remove(StoreAdrReg)
  OtherRegs.remove(rd)
  try:
    OtherRegs.remove(0)
  except:
    pass
  try:
    OtherRegs.remove(rs)
  except:
    pass
  DataReg = choice(OtherRegs)
  OtherRegs.remove(DataReg)
  OtherRd = choice(OtherRegs)
  return (rd,rs,DataReg,OtherRd)

def addInst(line):
  global CurrAdr
  f.write(line)
  if ("li x" in line):
    CurrAdr += 8 if (xlen == 32) else 20
  elif ("la x" in line):
    CurrAdr += 8
  else:
    CurrAdr += 4

def writeForwardsJumpVector(spacers):
  global TestNum
  rd, rs, DataReg, OtherRd = registerSelect()
  if (xlen==64):
    expected = int("fedbca9876540000",16)
    unexpected = int("ffff0000ffff0000",16)
  else:
    expected = int("fedbca98",16)
    unexpected = int("ff00ff00",16)


  f.write("\n")
  f.write("    # Testcase "+str(TestNum)+"  address cmp result rd:x"+str(rd)+"("+formatstr.format(CurrAdr+44)+")  data result rd:x"+str(DataReg)+"("+formatstr.format(expected)+")\n")
  addInst("    li x"+str(DataReg)+", "+formatstr.format(expected)+"\n")
  addInst("    JAL x"+str(rd)+", 1f\n")
  LinkAdr = CurrAdr if (rd!=0) else 0 # rd's expected value
  for i in range(spacers):
    addInst("    li x"+str(DataReg)+", "+formatstr.format(unexpected)+"\n")
  f.write("1:\n")
  addInst("    "+storecmd+" x"+str(rd)+", "+str(wordsize*(2*TestNum+0))+"(x"+str(StoreAdrReg)+")\n")
  f.write("    RVTEST_IO_ASSERT_GPR_EQ(x"+str(StoreAdrReg+1)+", x"+str(rd)+", "+formatstr.format(LinkAdr)+")\n")
  addInst("    "+storecmd+" x"+str(DataReg)+", "+str(wordsize*(2*TestNum+1))+"(x"+str(StoreAdrReg)+")\n")
  f.write("    RVTEST_IO_ASSERT_GPR_EQ(x"+str(StoreAdrReg+1)+", x"+str(DataReg)+", "+formatstr.format(expected)+")\n")
  writeExpectedToRef(LinkAdr)
  writeExpectedToRef(expected) 
  TestNum = TestNum+1

def writeBackwardsJumpVector(spacers):
  global TestNum
  rd, rs, DataReg,OtherRd = registerSelect()
  if (xlen==64):
    expected = int("fedbca9876540000",16)
    unexpected = int("ffff0000ffff0000",16)
  else:
    expected = int("fedbca98",16)
    unexpected = int("ff00ff00",16)

  f.write("\n")
  f.write("    # Testcase "+str(TestNum)+"  address cmp result rd:x"+str(rd)+"("+formatstr.format(CurrAdr+20+8*spacers)+")  data result rd:x"+str(DataReg)+"("+formatstr.format(expected)+")\n")
  addInst("    JAL x"+str(OtherRd)+", 2f\n")
  f.write("1:\n")
  addInst("    li x"+str(DataReg)+", "+formatstr.format(expected)+"\n")
  addInst("    JAL x"+str(OtherRd)+", 3f\n")
  f.write("2:\n")
  for i in range(spacers):
    addInst("    li x"+str(DataReg)+", "+formatstr.format(unexpected)+"\n")
  addInst("    JAL x"+str(rd)+", 1b\n")
  LinkAdr = CurrAdr if (rd!=0) else 0 # rd's expected value
  f.write("3:\n")
  addInst("    "+storecmd+" x"+str(rd)+", "+str(wordsize*(2*TestNum+0))+"(x"+str(StoreAdrReg)+")\n")
  f.write("    RVTEST_IO_ASSERT_GPR_EQ(x"+str(StoreAdrReg+1)+", x"+str(rd)+", "+formatstr.format(LinkAdr)+")\n")
  addInst("    "+storecmd+" x"+str(DataReg)+", "+str(wordsize*(2*TestNum+1))+"(x"+str(StoreAdrReg)+")\n")
  f.write("    RVTEST_IO_ASSERT_GPR_EQ(x"+str(StoreAdrReg+1)+", x"+str(DataReg)+", "+formatstr.format(expected)+")\n")
  writeExpectedToRef(LinkAdr)
  writeExpectedToRef(expected) 
  TestNum = TestNum+1

def writeChainVector(repetitions,spacers):
  global TestNum
  rd, rs, DataReg,OtherRd = registerSelect()
  if (xlen==64):
    expected = int("fedbca9876540000",16)
    unexpected = int("ffff0000ffff0000",16)
  else:
    expected = int("fedbca98",16)
    unexpected = int("ff00ff00",16)

  f.write("\n")
  f.write("    # Testcase "+str(TestNum)+"  address cmp result rd:x"+str(rd)+"(ugh; if you really wanted to, you could figure it out)  data result rd:x"+str(DataReg)+"("+formatstr.format(expected)+")\n")
  addInst("    li x"+str(DataReg)+", "+formatstr.format(expected)+"\n")
  for i in range(repetitions):
    addInst("    JAL x"+str(OtherRd)+", "+str(3*i+2)+"f\n")
    if spacers:
      for j in range(i):
        addInst("    li x"+str(DataReg)+", "+formatstr.format(unexpected)+"\n")
    f.write(str(3*i+1)+":\n")
    addInst("    JAL x"+str(OtherRd)+", "+str(3*i+3)+"f\n")
    if spacers:
      for j in range(i):
        addInst("    li x"+str(DataReg)+", "+formatstr.format(unexpected)+"\n")
    f.write(str(3*i+2)+":\n")
    addInst("    JAL x"+str(rd)+", "+str(3*i+1)+"b\n")
    LinkAdr = CurrAdr if (rd!=0) else 0 # rd's expected value
    if spacers:
      for j in range(i):
        addInst("    li x"+str(DataReg)+", "+formatstr.format(unexpected)+"\n")
    f.write(str(3*i+3)+":\n")
  addInst("    "+storecmd+" x"+str(rd)+", "+str(wordsize*(2*TestNum+0))+"(x"+str(StoreAdrReg)+")\n")
  f.write("    RVTEST_IO_ASSERT_GPR_EQ(x"+str(StoreAdrReg+1)+", x"+str(rd)+", "+formatstr.format(LinkAdr)+")\n")
  addInst("    "+storecmd+" x"+str(DataReg)+", "+str(wordsize*(2*TestNum+1))+"(x"+str(StoreAdrReg)+")\n")
  f.write("    RVTEST_IO_ASSERT_GPR_EQ(x"+str(StoreAdrReg+1)+", x"+str(DataReg)+", "+formatstr.format(expected)+")\n")
  writeExpectedToRef(LinkAdr)
  writeExpectedToRef(expected) 
  TestNum = TestNum+1


def writeExpectedToRef(expected):
  global TestGroupSizes
  TestGroupSizes[TestGroup-1] += 1
  if (xlen == 32):
    r.write(formatrefstr.format(expected)+"\n")
  else:
    r.write(formatrefstr.format(expected % 2**32)+"\n" + formatrefstr.format(expected >> 32)+"\n")

##################################
# main body
##################################

# change these to suite your tests
tests = ["JAL"]
author = "Ben Bracker (bbracker@hmc.edu)"
xlens = [32,64]
numtests = 100;

# setup
seed(0) # make tests reproducible

# generate files for each test
for xlen in xlens:
  CurrAdr = int("80000108",16)
  TestNum = 0
  TestGroup = 1
  TestGroupSizes = [0]
  AllRegs = list(range(0,32))
  UnusedRegs = deepcopy(AllRegs) 
  StoreAdrReg = 6 # matches what's in header script 
  UnusedRegs.remove(6)

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
    imperaspath = "../../imperas-riscv-tests/riscv-test-suite/rv" + str(xlen) + "i/"
    basename = "WALLY-" + test 
    fname = imperaspath + "src/" + basename + ".S"
    refname = imperaspath + "references/" + basename + ".reference_output"

    # print custom header part
    f = open(fname, "w")
    r = open(refname, "w")
    f.write("///////////////////////////////////////////\n")
    f.write("// "+fname+ "\n")
    f.write("//\n")
    f.write("// This file can be used to test the RISC-V JAL instruction.\n")
    f.write("// But be warned that altering the test environment may break this test!\n")
    f.write("// In order to work, this test expects that the first instruction (la)\n")
    f.write("// be allocated at 0x80000100.\n")
    f.write("//\n")
    f.write("// " + author + "\n")
    f.write("// Created "+str(datetime.now())+"\n") 
    
    # insert generic header
    h = open("testgen_header.S", "r")
    for line in h:  
      f.write(line)

    # print directed test vectors
    for i in range(0,31):
      writeForwardsJumpVector(randint(0,4))
    for i in range(0,31):
      writeBackwardsJumpVector(randint(0,4))
    writeForwardsJumpVector(100)
    writeBackwardsJumpVector(100)
    writeChainVector(6,True)
    writeChainVector(16,False)

    # print footer
    h = open("testgen_footer.S", "r")
    for line in h:  
      f.write(line)

    # Finish
    f.write(".fill "+str(sum(TestGroupSizes))+", "+str(wordsize)+", -1\n")
    f.write("\nRV_COMPLIANCE_DATA_END\n")
    f.close()
    r.close()




