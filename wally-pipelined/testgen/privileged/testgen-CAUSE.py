#!/usr/bin/python3
##################################
# testgen-CAUSE.py
#
# dottolia@hmc.edu 1 Mar 2021
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

#For instruction-fetch access or page-fault exceptions on systems with variable-length instructions, mtval will contain the virtual address of the portion of the instruction that caused the fault while mepc will point to the beginning of the instruction.

def randRegs():
  reg1 = randint(1,20)
  reg2 = randint(1,20)
  reg3 = randint(1,20)
  if (reg1 == 6 or reg2 == 6 or reg3 == 6 or reg1 == reg2):
    return randRegs()
  else:
      return str(reg1), str(reg2), str(reg3)

def writeVectors(storecmd):
  global testnum

    # Page 6 of unpriviledged spec
  # For both CSRRS and CSRRC, if rs1=x0, then the instruction will not write to the CSR at all, and so shall not cause any of the side effects

  # User Software Interrupt: True, 0
  # Supervisor Software Interrupt: True, 1
  # Machine Software Interrupt: True, 2

  # When running run.sh CAUSE -c, everything works, but begin_signature doesn't appear
  # 0x2000000 in wally
  # writeTest(storecmd, f, r, f"""
  #   la x10, 0x2000000 #clint

  #   li x1, 42
  #   sw x1, 0(x10)
  # """, True, 2, "m", f"""
  #   lw x0, 0(x10)
  # """)

  # User Timer Interrupt: True, 4
  # Supervior timer interrupt: True, 5
  # Machine timer interrupt: True, 7

  # writeTest(storecmd, f, r, f"""
  #   li x10, MASK_XLEN(0x8)
  #   csrrs x0, mstatus, x10

  #   li x11, MASK_XLEN(0x80)
  #   csrrs x0, mie, x11

  #   la x18, 0x2004000
  #   lw x11, 0(x18)
  #   lw x12, 4(x18)
  #   {storecmd} x0, 0(x18)
  #   {storecmd} x0, 4(x18)
  #   nop
  #   nop
  # """, True, 7, "m", f"""
  #   la x18, 0x2004000
  #   {storecmd} x11, 0(x18)
  #   {storecmd} x12, 4(x18)
  # """)

  #writeTest(storecmd, f, r, f"""
  #  li x2, 0x0
#
  #   li x4, 0x80
  #   csrrs x0, mie, x4

  #   la x2, 0x2004000
    
  #   li x3, 0x0
  #   lw x5, 0(x2)
  #   sd x3, 0(x2)
  #   wfi
  # """, True, 7, "m", f"""
  #   t
  # """)

  # writeTest(storecmd, f, r, f"""
  #   csrr x18, mstatus
  #   # csrsi mstatus, 0b11111
  #   csrr x19, mie
  #   li x17, 0b1111111111111
  #   # csrs mie, x17

  #   la x10, 0x2004000 #clint timer
  #   li x1, 0

  #   lw x11, 0(x10)
  #   lw x12, 4(x10)

  #   {storecmd} x0, 0(x10)
  #   {storecmd} x0, 4(x10)
  # """, True, 7, "m", f"""
  #   {storecmd} x11, 0(x10)
  #   {storecmd} x12, 4(x10)

  #   csrw mstatus, x18
  #   csrw mie, x19
  # """)

  # User external input: True, 8
  # Supervisor external input: True, 9
  # Machine externa input: True, 11

  # Instruction address misaligned: False, 0
  # looks like this is giving us an infinite loop for wally
  # BUG: jumping to a misaligned instruction address doesn't cause an exception: we actually jump...
  # Either that, or somehow at the end we always end up at 0x80004002
  # This is fine in OVPsim
  # writeTest(storecmd, f, r, f"""
  #   li x1, 11
  #   jr x1 # Something about this instruction is funky on wally, but fine with ovpsim
  # """, False, 0)

  # Instruction access fault: False, 1

  # Illegal Instruction 
  writeTest(storecmd, f, r, f"""
    .fill 1, 4, 0
  """, False, 2)

  # Breakpoint
  writeTest(storecmd, f, r, f"""
    ebreak
  """, False, 3)

  # Load Address Misaligned 
  writeTest(storecmd, f, r, f"""
    lw x0, 11(x0)
  """, False, 4)

  # Load Access fault: False, 5

  # Store/AMO address misaligned
  writeTest(storecmd, f, r, f"""
    sw x0, 11(x0)
  """, False, 6)

  # Environment call from u-mode: only for when only M and U mode enabled?
  writeTest(storecmd, f, r, f"""
    ecall
  """, False, 8, "u")

  # # Environment call from s-mode
  writeTest(storecmd, f, r, f"""
    ecall
  """, False, 9, "s")

  # Environment call from m-mode
  writeTest(storecmd, f, r, f"""
    ecall
  """, False, 11, "m")  

  # Instruction page fault: 12
  # Load page fault: 13
  # Store/AMO page fault: 15
  

  

def writeTest(storecmd, f, r, test, interrupt, code, mode = "m", resetHander = ""):
  global testnum

  expected = code
  if(interrupt):
    expected+=(1 << (wordsize - 1))


  trapEnd = ""
  before = ""
  if mode != "m":
    before = f"""
      li x1, 0b110000000000
      csrrc x28, mstatus, x1
      li x1, 0b{"01" if mode == "s" else "00"}00000000000
      csrrs x28, mstatus, x1

      auipc x1, 0
      addi x1, x1, 16 # x1 is now right after the mret instruction
      csrrw x27, mepc, x1
      mret

      # We're now in {mode} mode...
    """

    trapEnd = f"""j _jend{testnum}"""


  # Setup
  # TODO: Adding 8 to x30 won't work for 32 bit?
  # x31: Old mtvec value
  # x30: trap handler address
  # x29: Old mtvec value for user/supervisor mode
  # x28: Old mstatus value
  # x27: Old mepc value
  # x26: 0 if we should execute mret normally. 1 otherwise. This allows us to stay in machine
  # x25: mcause
  # mode for the next tests
  lines = f"""
    # Testcase {testnum}
    csrrs x31, mtvec, x0

    auipc x30, 0
    addi x30, x30, 12
    j _jtest{testnum}

    # Machine trap vector
    {resetHander}
    csrrs x25, mcause, x0
    csrrs x1, mepc, x0
    addi x1, x1, 4
    csrrw x0, mepc, x1
    {trapEnd}
    mret

    # Actual test
    _jtest{testnum}:
    csrrw x0, mtvec, x30

    # Start test code
    li x25, 0x7BAD
    {before}
    {test}

    # Finished test. Reset to old mtvec
    _jend{testnum}:

    csrrw x0, mtvec, x31
  """

  #expected = 42
  
  lines += storecmd + " x25, " + str(wordsize*testnum) + "(x6)\n"
  #lines += "RVTEST_IO_ASSERT_GPR_EQ(x7, " + str(reg2) +", "+formatstr.format(expected)+")\n"
  f.write(lines)
  if (xlen == 32):
    line = formatrefstr.format(expected)+"\n"
  else:
    line = formatrefstr.format(expected % 2**32)+"\n" + formatrefstr.format(expected >> 32) + "\n"
  r.write(line)
  testnum = testnum+1

  # lines += storecmd + " x0" + ", " + str(wordsize*testnum) + "(x6)\n"
  # #lines += "RVTEST_IO_ASSERT_GPR_EQ(x7, " + str(reg2) +", "+formatstr.format(expected)+")\n"
  # f.write(lines)
  # if (xlen == 32):
  #   line = formatrefstr.format(expected)+"\n"
  # else:
  #   line = formatrefstr.format(expected % 2**32)+"\n" + formatrefstr.format(expected >> 32) + "\n"
  # r.write(line)
  # testnum = testnum+1

##################################
# main body
##################################

# change these to suite your tests
# csrrw, csrrs, csrrc, csrrwi, csrrsi, csrrci
author = "dottolia@hmc.edu"
xlens = [32, 64]
numrand = 10;

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

  corners = [
    0x624B3E976C52DD14 % 2**xlen, 2**(xlen-1)-2, 2**(xlen-1)-1, 
    2**(xlen-1), 2**(xlen-1)+1, 0xC365DDEB9173AB42 % 2**xlen, 2**(xlen)-2, 2**(xlen)-1
  ]
  imperaspath = "../../../imperas-riscv-tests/riscv-test-suite/rv" + str(xlen) + "p/"
  basename = "WALLY-CAUSE"
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
  h = open("../testgen_header.S", "r")
  for line in h:  
    f.write(line)

  # print directed and random test vectors
  for i in range(0,numrand):
    writeVectors(storecmd)


  # print footer
  h = open("../testgen_footer.S", "r")
  for line in h:  
    f.write(line)

  # Finish
  lines = ".fill " + str(testnum) + ", " + str(wordsize) + ", -1\n"
  lines = lines + "\nRV_COMPLIANCE_DATA_END\n" 
  f.write(lines)
  f.close()
  r.close()




