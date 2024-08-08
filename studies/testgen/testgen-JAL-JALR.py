#!/usr/bin/env python3
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
# helper functions
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
  UnusedRegs.remove(rd)
  OtherRegs = deepcopy(UnusedRegs)
  if 0 in OtherRegs: 
    OtherRegs.remove(0)
  if len(OtherRegs) == 0:
    OtherRegs = deepcopy(AllRegs)
    OtherRegs.remove(0)
  rs = choice(OtherRegs)
  OtherRegs = deepcopy(AllRegs)
  OtherRegs.remove(StoreAdrReg)
  OtherRegs.remove(rd)
  if 0 in OtherRegs: 
    OtherRegs.remove(0)
  if rs in OtherRegs: 
    OtherRegs.remove(rs)
  DataReg = choice(OtherRegs)
  OtherRegs.remove(DataReg)
  OtherRd = choice(OtherRegs)
  return (rd,rs,DataReg,OtherRd)

def addInst(line):
  global CurrAdr
  f.write(line)
  if ("li x" in line) and ("slli x" not in line):
    CurrAdr += 8 if (xlen == 32) else 20
  elif ("la x" in line):
    CurrAdr += 8
  else:
    CurrAdr += 4

def expectValue(expectReg, expectVal, sigOffset):
  global TestGroupSizes
  TestGroupSizes[TestGroup-1] += 1
  addInst("    "+storecmd+" x"+str(expectReg)+", "+str(wordsize*sigOffset)+"(x"+str(StoreAdrReg)+")\n")
  f.write("    RVTEST_IO_ASSERT_GPR_EQ(x"+str(StoreAdrReg+1)+", x"+str(expectReg)+", "+formatstr.format(expectVal)+")\n")
  if (xlen == 32):
    r.write(formatrefstr.format(expectVal)+"\n")
  else:
    r.write(formatrefstr.format(expectVal % 2**32)+"\n" + formatrefstr.format(expectVal >> 32)+"\n")

def addJalr(rs,rd,dist):
  target = CurrAdr + 20 + dist
  target31_12 = CurrAdr >> 12 # 20 bits for lui
  target11_0 = target - (target31_12 << 12) # 12 remaining bits
  target31_16 = target31_12 >> 4 # lui sign extends, so shift in a leading 0
  target15_12 = target31_12 - (target31_16 << 4) # the nibble we just lost
  if target11_0 > 0:
    offset = randint(-(1<<11)-1,(1<<11)-2-target11_0)
  else:
    offset = randint(-(1<<11)-1-target11_0,(1<<11)-2)
  addInst("    lui x"+str(rs)+", 0x"+imm20formatstr.format(target31_16)+"\n")
  addInst("    addi x"+str(rs)+", x"+str(rs)+", SEXT_IMM(0x0"+imm12formatstr.format(target15_12 << 8)+")\n")
  addInst("    slli x"+str(rs)+", x"+str(rs)+", SEXT_IMM(4)\n") 
  addInst("    addi x"+str(rs)+", x"+str(rs)+", SEXT_IMM(0x"+imm12formatstr.format(0xfff&(offset+target11_0+randint(0,1)))+")\n")
  addInst("    JALR x"+str(rd)+", x"+str(rs)+", SEXT_IMM(0x"+imm12formatstr.format(0xfff&(-offset))+")\n")

##################################
# test functions
##################################
def writeForwardsJumpVector(spacers,instr):
  global TestNum
  TestNum += 1
  rd, rs, DataReg, OtherRd = registerSelect()
  # Header
  f.write("\n")
  f.write("    # Testcase "+str(TestNum)+"\n")
  # Test Code
  addInst("    li x"+str(DataReg)+", "+formatstr.format(expected)+"\n")
  if (instr=="JAL"):
    addInst("    JAL x"+str(rd)+", 1f\n")
  elif (instr=="JALR"):
    dist = spacers*(8 if (xlen == 32) else 20) # Compute distance from linked adr to target adr
    addJalr(rs,rd,dist);
  else:
    exit("invalid instruction") 
  LinkAdr = CurrAdr if (rd!=0) else 0 # rd's expected value
  for i in range(spacers):
    addInst("    li x"+str(DataReg)+", "+formatstr.format(unexpected)+"\n")
  f.write("1:\n")
  # Store values to be verified
  expectValue(rd, LinkAdr, 2*TestNum+0)
  expectValue(DataReg, expected, 2*TestNum+1)

def writeBackwardsJumpVector(spacers,instr):
  global TestNum
  TestNum += 1
  rd, rs, DataReg, OtherRd = registerSelect()
  # Header
  f.write("\n")
  f.write("    # Testcase "+str(TestNum)+"\n")
  # Test Code
  addInst("    JAL x"+str(OtherRd)+", 2f\n")
  f.write("1:\n")
  addInst("    li x"+str(DataReg)+", "+formatstr.format(expected)+"\n")
  addInst("    JAL x"+str(OtherRd)+", 3f\n")
  f.write("2:\n")
  for i in range(spacers):
    addInst("    li x"+str(DataReg)+", "+formatstr.format(unexpected)+"\n")
  if (instr=="JAL"):
    addInst("    JAL x"+str(rd)+", 1b\n")
  elif (instr=="JALR"):
    dist = -20 - 4 - (1+spacers)*(8 if (xlen == 32) else 20) # Compute distance from linked adr to target adr
    addJalr(rs,rd,dist);
  else:
    exit("invalid instruction") 
  LinkAdr = CurrAdr if (rd!=0) else 0 # rd's expected value
  f.write("3:\n")
  # Store values to be verified
  expectValue(rd, LinkAdr, 2*TestNum+0)
  expectValue(DataReg, expected, 2*TestNum+1)

def writeChainVector(repetitions,spacers):
  global TestNum
  TestNum += 1
  rd, rs, DataReg,OtherRd = registerSelect()
  # Header
  f.write("\n")
  f.write("    # Testcase "+str(TestNum)+"\n")
  # Test Code
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
  # Store values to be verified
  expectValue(rd, LinkAdr, 2*TestNum+0)
  expectValue(DataReg, expected, 2*TestNum+1)

##################################
# main body
##################################

# change these to suite your tests
test = 0
tests = ["JAL","JALR"]
author = "Ben Bracker (bbracker@hmc.edu)"
xlens = [32,64]
numtests = 100

# setup
seed(0) # make tests reproducible

# generate files for each test
for test in tests:
  for xlen in xlens:
    print(test+" "+str(xlen))
    CurrAdr = int("80000108",16)
    TestNum = -1
    TestGroup = 1
    TestGroupSizes = [0]
    AllRegs = list(range(0,32))
    UnusedRegs = deepcopy(AllRegs) 
    StoreAdrReg = 6 # matches what's in header script 
    UnusedRegs.remove(6)
    if (xlen==64):
      expected = int("fedbca9876540000",16)
      unexpected = int("ffff0000ffff0000",16)
    else:
      expected = int("fedbca98",16)
      unexpected = int("ff00ff00",16)

    formatstrlen = str(int(xlen/4))
    formatstr = "0x{:0" + formatstrlen + "x}" # format as xlen-bit hexadecimal number
    formatrefstr = "{:08x}" # format as xlen-bit hexadecimal number with no leading 0x
    imm20formatstr = "{:05x}"
    imm12formatstr = "{:03x}"

    if (xlen == 32):
      storecmd = "sw"
      wordsize = 4
    else:
      storecmd = "sd"
      wordsize = 8

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
    f.write("// This file can be used to test the RISC-V JAL(R) instruction.\n")
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
    if test == "JAL":
      for i in range(0,31):
        writeForwardsJumpVector(randint(0,4),"JAL")
      for i in range(0,31):
        writeBackwardsJumpVector(randint(0,4),"JAL")
      writeForwardsJumpVector(100,"JAL")
      writeBackwardsJumpVector(100,"JAL")
      writeChainVector(6,True)
      writeChainVector(16,False)
    elif test == "JALR":
      for i in range(0,31):
        writeForwardsJumpVector(randint(0,4),"JALR")
      for i in range(0,31):
        writeBackwardsJumpVector(randint(0,4),"JALR")
      # can't make these latter two too long else 12 bit immediate overflows
      # (would need to lui or slli rs to achieve longer ranges)
      writeForwardsJumpVector(15,"JALR")
      writeBackwardsJumpVector(15,"JALR")

    # print footer
    h = open("testgen_footer.S", "r")
    for line in h:  
      f.write(line)

    # Finish
    f.write(".fill "+str(sum(TestGroupSizes))+", "+str(wordsize)+", -1\n")
    f.write("\nRV_COMPLIANCE_DATA_END\n")
    f.close()
    r.close()
