#!/usr/bin/python3
##################################
# covergen.py
#
# David_Harris@hmc.edu 27 March 2024
#
# Generate directed tests for functional coverage
##################################

##################################
# libraries
##################################
from datetime import datetime
from random import randint 
from random import seed
from random import getrandbits
import os
import re

##################################
# functions
##################################

def shiftImm(imm, xlen):
  imm = imm % xlen
  return str(imm)

def signedImm12(imm):
  imm = imm % pow(2, 12)
  if (imm & 0x800):
    imm = imm - 0x1000
  return str(imm)

def writeCovVector(desc, rs1, rs2, rd, rs1val, rs2val, immval, rdval, test, storecmd, xlen):
  lines = "\n# Testcase " + str(desc) + "\n"
  if (rs1val < 0):
    rs1val = rs1val + 2**xlen
  if (rs2val < 0):
    rs2val = rs2val + 2**xlen
  lines = lines + "li x" + str(rd) + ", " + formatstr.format(rdval) + " # initialize rd to a random value that should get changed\n"
  if (test in rtype):
    lines = lines + "li x" + str(rs1) + ", " + formatstr.format(rs1val) + " # initialize rs1 to a random value \n"
    lines = lines + "li x" + str(rs2) + ", " + formatstr.format(rs2val) + " # initialize rs2 to a random value\n"
    lines = lines + test + " x" + str(rd) + ", x" + str(rs1) + ", x" + str(rs2) + " # perform operation\n" 
  elif (test in shiftitype):
    lines = lines + "li x" + str(rs1) + ", " + formatstr.format(rs1val) + " # initialize rs1 to a random value \n"
    lines = lines + test + " x" + str(rd) + ", x" + str(rs1) + ", " + shiftImm(immval, xlen) + " # perform operation\n"
  elif (test in itype):
    lines = lines + "li x" + str(rs1) + ", " + formatstr.format(rs1val) + " # initialize rs1 to a random value \n"
    lines = lines + test + " x" + str(rd) + ", x" + str(rs1) + ", " + signedImm12(immval) + " # perform operation\n"
  else:
    pass
    #print("Error: %s type not implemented yet" % test)
  f.write(lines)

def randomize():
    rs1 = randint(1, 31)
    rs2 = randint(1, 31)
    # choose rd that is different than rs1 and rs2
    rd = rs1
    while (rd == rs1 or rd == rs2):
      rd = randint(1, 31)
    rd = randint(1, 31)
    rs1val = randint(0, 2**xlen-1)
    rs2val = randint(0, 2**xlen-1)
    immval = randint(0, 2**xlen-1)
    rdval = randint(0, 2**xlen-1)
    return [rs1, rs2, rd, rs1val, rs2val, immval, rdval]

def make_rd(test, storecmd, xlen):
  for r in range(32):
    [rs1, rs2, rd, rs1val, rs2val, immval, rdval] = randomize()
    desc = "cp_rd (Test destination rd = x" + str(r) + ")"
    writeCovVector(desc, rs1, rs2, r, rs1val, rs2val, immval, rdval, test, storecmd, xlen)

def make_rs1(test, storecmd, xlen):
  for r in range(32):
    [rs1, rs2, rd, rs1val, rs2val, immval, rdval] = randomize()
    desc = "cp_rs1 (Test source rs1 = x" + str(r) + ")"
    writeCovVector(desc, r, rs2, rd, rs1val, rs2val, immval, rdval, test, storecmd, xlen)

def make_rs2(test, storecmd, xlen):
  for r in range(32):
    [rs1, rs2, rd, rs1val, rs2val, immval, rdval] = randomize()
    desc = "cp_rs2 (Test source rs2 = x" + str(r) + ")"
    writeCovVector(desc, rs1, r, rd, rs1val, rs2val, immval, rdval, test, storecmd, xlen)

def make_rd_rs1(test, storecmd, xlen):
  for r in range(32):
    [rs1, rs2, rd, rs1val, rs2val, immval, rdval] = randomize()
    desc = "cmp_rd_rs1 (Test rd = rs1 = x" + str(r) + ")"
    writeCovVector(desc, r, rs2, r, rs1val, rs2val, immval, rdval, test, storecmd, xlen)

def make_rd_rs2(test, storecmd, xlen):
  for r in range(32):
    [rs1, rs2, rd, rs1val, rs2val, immval, rdval] = randomize()
    desc = "cmp_rd_rs2 (Test rd = rs1 = x" + str(r) + ")"
    writeCovVector(desc, rs1, r, r, rs1val, rs2val, immval, rdval, test, storecmd, xlen)

def make_rd_rs1_rs2(test, storecmd, xlen):
  for r in range(32):
    [rs1, rs2, rd, rs1val, rs2val, immval, rdval] = randomize()
    desc = "cmp_rd_rs1_rs2 (Test rd = rs1 = rs2 = x" + str(r) + ")"
    writeCovVector(desc, r, r, r, rs1val, rs2val, immval, rdval, test, storecmd, xlen)

def make_rs1_rs2(test, storecmd, xlen):
  for r in range(32):
    [rs1, rs2, rd, rs1val, rs2val, immval, rdval] = randomize()
    desc = "cmp_rd_rs1_rs2 (Test rs1 = rs2 = x" + str(r) + ")"
    writeCovVector(desc, r, r, rd, rs1val, rs2val, immval, rdval, test, storecmd, xlen)

def make_rs1_maxvals(test, storecmd, xlen):
   for v in [0, 2**(xlen-1), 2**(xlen-1)-1, 2**xlen-1, 1, 2**(xlen-1)+1]:
    [rs1, rs2, rd, rs1val, rs2val, immval, rdval] = randomize()
    desc = "cp_rs1_maxvals (Test source rs1 value = " + hex(v) + ")"
    writeCovVector(desc, rs1, rs2, rd, v, rs2val, immval, rdval, test, storecmd, xlen)

def make_rs2_maxvals(test, storecmd, xlen):
   for v in [0, 2**(xlen-1), 2**(xlen-1)-1, 2**xlen-1, 1, 2**(xlen-1)+1]:
    [rs1, rs2, rd, rs1val, rs2val, immval, rdval] = randomize()
    desc = "cp_rs2_maxvals (Test source rs2 value = " + hex(v) + ")"
    writeCovVector(desc, rs1, rs2, rd, rs1val, v, immval, rdval, test, storecmd, xlen)

def make_rd_maxvals(test, storecmd, xlen):
   for v in [0, 2**(xlen-1), 2**(xlen-1)-1, 2**xlen-1, 1, 2**(xlen-1)+1]:
    [rs1, rs2, rd, rs1val, rs2val, immval, rdval] = randomize()
    desc = "cp_rd_maxvals (Test rd value = " + hex(v) + ")"
    writeCovVector(desc, rs1, 0, rd, v, rs2val, immval, rdval, test, storecmd, xlen)

def make_rd_rs1_eqval(test, storecmd, xlen):
  [rs1, rs2, rd, rs1val, rs2val, immval, rdval] = randomize()
  desc = "cmp_rdm_rs1_eqval (Test rs1 = rd = " + hex(rs1val) + ")"
  writeCovVector(desc, rs1, 0, rd, rs1val, rs2val, immval, rdval, test, storecmd, xlen)

def make_rd_rs2_eqval(test, storecmd, xlen):
  [rs1, rs2, rd, rs1val, rs2val, immval, rdval] = randomize()
  desc = "cmp_rd_rs2_eqval (Test rs2 = rd = " + hex(rs2val) + ")"
  writeCovVector(desc, 0, rs2, rd, rs1val, rs2val, immval, rdval, test, storecmd, xlen)

def make_rs1_rs2_eqval(test, storecmd, xlen):
  [rs1, rs2, rd, rs1val, rs2val, immval, rdval] = randomize()
  desc = "cmp_rs1_rs2_eqval (Test rs1 = rs2 = " + hex(rs1val) + ")"
  writeCovVector(desc, rs1, rs2, rd, rs1val, rs1val, immval, rdval, test, storecmd, xlen)

#def make_cp_gpr_hazard(test, storecmd, xlen):
#  pass # *** to be implemented ***

def make_rs1_sign(test, storecmd, xlen):
   for v in [1, -1]:
    [rs1, rs2, rd, rs1val, rs2val, immval, rdval] = randomize()
    rs1val = abs(rs1val % 2**(xlen-1)) * v;
    desc = "cp_rs1_sign (Test source rs1 value = " + hex(rs1val) + ")"
    writeCovVector(desc, rs1, rs2, rd, rs1val, rs2val, immval, rdval, test, storecmd, xlen)

def make_rs2_sign(test, storecmd, xlen):
  for v in [1, -1]:
    [rs1, rs2, rd, rs1val, rs2val, immval, rdval] = randomize()
    rs2val = abs(rs2val % 2**(xlen-1)) * v;
    desc = "cp_rs2_sign (Test source rs2 value = " + hex(rs2val) + ")"
    writeCovVector(desc, rs1, rs2, rd, rs1val, rs2val, immval, rdval, test, storecmd, xlen)

def make_cr_rs1_rs2_sign(test, storecmd, xlen):
  for v1 in [1, -1]:
    for v2 in [1, -1]:
      [rs1, rs2, rd, rs1val, rs2val, immval, rdval] = randomize()
      rs1val = abs(rs1val % 2**(xlen-1)) * v1;
      rs2val = abs(rs2val % 2**(xlen-1)) * v2;
      desc = "cr_rs1_rs2 (Test source rs1 = " + hex(rs1val) + " rs2 = " + hex(rs2val) + ")"
      writeCovVector(desc, rs1, rs2, rd, rs1val, rs2val, immval, rdval, test, storecmd, xlen)

def write_tests(coverpoints, test, storecmd, xlen):
  for coverpoint in coverpoints:
    if (coverpoint == "cp_asm_count"):
      pass
    elif (coverpoint == "cp_rd"):
      make_rd(test, storecmd, xlen)
    elif (coverpoint == "cp_rs1"):
      make_rs1(test, storecmd, xlen)
    elif (coverpoint == "cp_rs2"):
      make_rs2(test, storecmd, xlen)
    elif (coverpoint == "cmp_rd_rs1"):
      make_rd_rs1(test, storecmd, xlen)
    elif (coverpoint == "cmp_rd_rs2"):
      make_rd_rs2(test, storecmd, xlen)
    elif (coverpoint == "cmp_rd_rs1_rs2"):
      make_rd_rs1_rs2(test, storecmd, xlen)
    elif (coverpoint == "cmp_rd_rs1_eq"):
      pass # duplicate of cmp_rd_rs1
    elif (coverpoint == "cmp_rd_rs2_eq"):
      pass # duplicate of cmp_rd_rs2
    elif (coverpoint == "cmp_rs1_rs2_eq"):
      make_rs1_rs2(test, storecmd, xlen)
    elif (coverpoint == "cp_rs1_maxvals"):
      make_rs1_maxvals(test, storecmd, xlen)
    elif (coverpoint == "cp_rs2_maxvals"):
      make_rs2_maxvals(test, storecmd, xlen)
    elif (coverpoint == "cp_rd_maxvals"):
      make_rd_maxvals(test, storecmd, xlen)
    elif (coverpoint == "cmp_rd_rs1_eqval"):
      make_rd_rs1_eqval(test, storecmd, xlen)
    elif (coverpoint == "cmp_rd_rs2_eqval"):
      make_rd_rs2_eqval(test, storecmd, xlen)
    elif (coverpoint == "cmp_rs1_rs2_eqval"):
      make_rs1_rs2_eqval(test, storecmd, xlen)
    elif (coverpoint == "cp_rs1_sign"):
      make_rs1_sign(test, storecmd, xlen)
    elif (coverpoint == "cp_rs2_sign"):
      make_rs2_sign(test, storecmd, xlen)
    elif (coverpoint == "cp_rd_sign"):
      pass # hope already covered by rd_maxvals
    elif (coverpoint == "cr_rs1_rs2"):
      make_cr_rs1_rs2_sign(test, storecmd, xlen)
    elif (coverpoint == "cp_rs1_toggle"):
      pass # toggle not needed and seems to be covered by other things
    elif (coverpoint == "cp_rs2_toggle"):
      pass # toggle not needed and seems to be covered by other things
    elif (coverpoint == "cp_rd_toggle"):
      pass # toggle not needed and seems to be covered by other things
    elif (coverpoint == "cp_gpr_hazard"):
      pass # not yet implemented
    else:
      print("Warning: " + coverpoint + " not implemented yet for " + test)
      
def getcovergroups(coverdefdir, coverfiles):
  coverpoints = {}
  curinstr = ""
  for coverfile in coverfiles:
    coverfile = coverdefdir + "/" + coverfile + "_coverage.svh"
    f = open(coverfile, "r")
    for line in f:
      m = re.search(r'cp_asm_count.*\"(.*)"', line)
      if (m):
#        if (curinstr != ""):
#          print(curinstr + ": " + str(coverpoints[curinstr]))
        curinstr = m.group(1)
        coverpoints[curinstr] = []
      m = re.search("\s*(\S+) :", line)
      if (m):
        coverpoints[curinstr].append(m.group(1))
    f.close()
    return coverpoints

##################################
# main body
##################################

# change these to suite your tests
riscv = os.environ.get("RISCV")
coverdefdir = riscv+"/ImperasDV-OpenHW/Imperas/ImpProprietary/source/host/riscvISACOV/source/coverage";
#coverfiles = ["RV64I", "RV64M", "RV64A", "RV64C", "RV64F", "RV64D"] # add more later
coverfiles = ["RV64I"] # add more later
rtype = ["add", "sub", "sll", "slt", "sltu", "xor", "srl", "sra", "or", "and",
          "addw", "subw", "sllw", "srlw", "sraw"
          "mul", "mulh", "mulhsu", "mulhu", "div", "divu", "rem", "remu",
          "mulw", "divw", "divuw", "remw", "remuw"]
loaditype = ["lb", "lh", "lw", "ld", "lbu", "lhu", "lwu"]
shiftitype = ["slli", "srli", "srai"]
itype = ["addi", "slti", "sltiu", "xori", "ori", "andi"]
stypes = ["sb", "sh", "sw", "sd"]
btypes = ["beq", "bne", "blt", "bge", "bltu", "bgeu"]
coverpoints = getcovergroups(coverdefdir, coverfiles)

author = "David_Harris@hmc.edu"
xlens = [64]
numrand = 3

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
  for test in coverpoints.keys():
#    pathname = "../wally-riscv-arch-test/riscv-test-suite/rv" + str(xlen) + "i_m/I/"
    WALLY = os.environ.get('WALLY')
    pathname = WALLY+"/tests/functcov/rv" + str(xlen) + "/I/"
    cmd = "mkdir -p " + pathname
    os.system(cmd)
    basename = "WALLY-COV-" + test 
    fname = pathname + "/" + basename + ".S"

    # print custom header part
    f = open(fname, "w")
    line = "///////////////////////////////////////////\n"
    f.write(line)
    lines="// "+fname+ "\n// " + author + "\n"
    f.write(lines)
    line ="// Created " + str(datetime.now()) 
    f.write(line)

    # insert generic header
    h = open("covergen_header.S", "r")
    for line in h:  
      f.write(line)

    # print directed and random test vectors
    # Coverage for R-type arithmetic instructions
    #if (test not in rtests):
    #  exit("Error: %s not implemented yet" % test)
    #else:
    #  write_rtype_arith_vectors(test, storecmd, xlen)
    write_tests(coverpoints[test], test, storecmd, xlen) 

    # print footer
    line = "\n.EQU NUMTESTS," + str(1) + "\n\n"
    f.write(line)
    h = open("covergen_footer.S", "r")
    for line in h:  
      f.write(line)

    # Finish
#    lines = ".fill " + str(testnum) + ", " + str(wordsize) + ", -1\n"
#    lines = lines + "\nRV_COMPLIANCE_DATA_END\n" 
    f.write(lines)
    f.close()




