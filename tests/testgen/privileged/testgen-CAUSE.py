#!/usr/bin/env python3
##################################
# testgen-CAUSE.py (new)
#
# dottolia@hmc.edu 1 Mar 2021
#
# Generate directed and random test vectors for RISC-V Design Validation.
#
#
##################################
# DOCUMENTATION:
#
# The most up-to-date comments explaining what everything
# does and the layout of the privileged tests
# can be found in testgen-TVAL.py. This and
# other files do not have as many comments
#
###################################

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

def writeVectors(storecmd, returningInstruction):
  global testnum

  if testMode == "m":
    if fromMode == "m":
      expectedCode = 7 if fromMode == "m" else 5
      clintAddr = "0x2004000"

      writeTest(storecmd, f, r, f"""
        li x1, 0x8
        csrrs x0, {fromMode}status, x1

        la x18, {clintAddr}
        {loadcmd} x11, 0(x18)
        li x1, 0x3fffffffffffffff
        {storecmd} x1, 0(x18)

        li x1, 0x80
        csrrs x0, {fromMode}ie, x1

        {storecmd} x0, 0(x18)
      """, True, expectedCode, f"""
        li x1, 0x80
        csrrc x0, {fromMode}ie, x1

        li x1, 0x8
        csrrc x0, {fromMode}status, x1

        la x18, {clintAddr}
        li x1, -1
        {storecmd} x1, 0(x18)
      """)

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

  # if fromMode == "m":
  #   clintAddr = "0x2004000"

  #   writeTest(storecmd, f, r, f"""
  #     # li x1, 0x8
  #     # csrrs x0, mstatus, x1

  #     # li x1, 0x80
  #     # csrrs x0, mie, x1

  #     # la x18, {clintAddr}
  #     # lw x11, 0(x18)
  #     # lw x12, 4(x18)
  #     # li x1, 1
  #     # {storecmd} x1, 0(x18)
  #     nop
  #     sub x1, x2, x3
  #     sub x2, x3, x4
  #     sub x3, x4, x5
  #     nop
  #     nop
  #     nop
  #     nop
  #     nop
  #     nop
  #     nop
  #     nop
  #     nop
  #     nop
  #     nop
  #     nop
  #     nop
  #     nop
  #     nop
  #     nop
  #   """, True, 7, f"""
  #     # la x18, {clintAddr}
  #     # {storecmd} x11, 0(x18)
  #   """)

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
  if returningInstruction != "ebreak":
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
  # writeTest(storecmd, f, r, f"""
  #   ecall
  # """, False, 8, "u")
  if returningInstruction != "ecall":
    if fromMode == "u":
      writeTest(storecmd, f, r, f"""
        ecall
      """, False, 8)

    # Environment call from s-mode
    if fromMode == "s":
      writeTest(storecmd, f, r, f"""
        ecall
      """, False, 9)

    # Environment call from m-mode
    if fromMode == "m":
      writeTest(storecmd, f, r, f"""
        ecall
      """, False, 11)  

  # Instruction page fault: 12
  # Load page fault: 13
  # Store/AMO page fault: 15
  

  

def writeTest(storecmd, f, r, test, interrupt, code, resetHander = ""):
  global testnum, storeAddressOffset

  expected = code
  if(interrupt):
    expected+=(1 << (xlen - 1))

  # The code we actually change for our test
  lines = f"""
    csrr x25, {testMode}cause
  """

  # Boilerplate
  #
  # x28 is the address that our trap handler will jump to before returning.
  # This is where we can do our actual tests. After we're done computing and storing
  # what we want, we jump to x27, which continues with the trap handling code (look at the _j_x_trap_... labels)
  # 
  lines = f"""
    la x28, _jtest{testnum}
    j _jdo{testnum}

    _jtest{testnum}:
    {lines}
    {resetHander}
    jr x27

    _jdo{testnum}:
    li x25, 0xDEADBEA7
    li gp, 0
    {test}
  """

  # We expect x25 to be 0 always. This is because of the code we wrote at the begining
  # of this function
  
  # Store the expected value of x25 to memory and in the .reference_output file
  lines += f"""
    {storecmd} x25, {testnum * wordsize}(x6)
  """

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

author = "dottolia@hmc.edu"
xlens = [32, 64]
testCount = 8;

# setup
# Change this seed to a different constant value for every test
seed(0xC363DAEB9193AB45) # make tests reproducible

# generate files for each test
for xlen in xlens:
  formatstrlen = str(int(xlen/4))
  formatstr = "0x{:0" + formatstrlen + "x}" # format as xlen-bit hexadecimal number
  formatrefstr = "{:08x}" # format as xlen-bit hexadecimal number with no leading 0x
  if (xlen == 32):
    storecmd = "sw"
    loadcmd = "lw"
    wordsize = 4
  else:
    storecmd = "sd"
    loadcmd = "ld"
    wordsize = 8

  # testMode can be m, s, and u. User mode traps are deprecated, so this should likely just be ["m", "s"]
  for testMode in ["m", "s"]:
    imperaspath = "../../../imperas-riscv-tests/riscv-test-suite/rv" + str(xlen) + "p/"
    basename = "WALLY-" + testMode.upper() + "CAUSE"
    fname = imperaspath + "src/" + basename + ".S"
    refname = imperaspath + "references/" + basename + ".reference_output"
    testnum = 0
    storeAddressOffset = 0

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
     f.write(line.replace("RV_COMPLIANCE_RV64M", "RV_COMPLIANCE_RV" + str(xlen) + "M"))
    # f.write(f"""
    #   #include "riscv_test_macros.h"
    #   #include "compliance_test.h"
    #   #include "compliance_io.h"

    #   0000000080000000 <_start>:
    #   80000000: 0480006f            j 80000048 <reset_vector>
    # """)

    # We need to leave at least one bit in medeleg unset so that we have a way to get
    # back to machine mode when the tests are complete (otherwise we'll only ever be able
    # to get up to supervisor mode). 
    #
    # So, we define a returning instruction which will be used to cause the exception that
    # brings us into machine mode. The bit for this returning instruction is NOT set in
    # medeleg. However, this also means that we can't test that instruction. So, we have
    # two different returning instructions.
    #
    # Current code is written to only support ebreak and ecall.
    #
    # For testgen-TVAL, we don't need to test ebreak, so we can use that as the sole
    # returning instruction. For others, like testgen-CAUSE, we'll need to put
    # both ebreak and ecall here.
    for returningInstruction in ["ebreak"]:

      # All registers used:
      # x30: set to 1 if we should return to & stay in machine mode after trap, 0 otherwise
      # ...
      # x28: address trap handler should jump to for the test
      # x27: address the test should return to after the test
      # ...
      # x25: value to write to memory
      # ...
      # x20: intermediate value in trap handler. Don't overwrite this!
      # x19: mtvec old value
      # x18: medeleg old value
      # x17: sedeleg old value (currently unused — user mode traps deprecated)
      # x16: mideleg old value
      # ...
      # x10 - x14 can be freely written
      # ...
      # x7: copy of x6. Increment this instead of using an offset on x6.
      #     this allows us to create more than 2048/wordlen tests.
      #     This is the address we write results to
      # x6: Starting address we should write expected results to
      # ...
      # x1 - x5 can be freely written  



      # Set up x7 and store old value of mtvec
      lines = f"""
        add x7, x6, x0
        csrr x19, mtvec

        slli  a0,a0,0x1f
        slli  a0,a0,0x1e
        slli  a0,a0,0x1d
        slli  a0,a0,0x1c
        slli  a0,a0,0x1b
        slli  a0,a0,0x1a
        slli  a0,a0,0x19
      """

      # Not used — user mode traps are deprecated
      if testMode == "u":
        lines += f"""
          csrr x17, sedeleg
          li x9, {"0b1100000000" if testMode == "u" else "0b0000000000"}
          csrs sedeleg, x9
          """

      # Code that will jump to the test (x28 is set in writeTest above)
      testJumpCode = f"""
        auipc x27, 0
        addi x27, x27, 12
        jr x28
      """

      # Code for handling traps in different modes
      # Some comments are inside of the below strings (prefixed with a #, as you might expected)
      lines += f"""
        # Reset x30 to 0 so we can run the tests. We'll set this to 1 when tests are completed so we stay in machine mode
        li x30, 0

        # Set up 
        la x1, _j_m_trap_{returningInstruction}
        csrw mtvec, x1
        la x1, _j_s_trap_{returningInstruction}
        csrw stvec, x1
        la x1, _j_u_trap_{returningInstruction}
        # csrw utvec, x1 # user mode traps are not supported

        # Start the tests!
        j _j_t_begin_{returningInstruction}

        # Machine mode traps
        _j_m_trap_{returningInstruction}:
        {testJumpCode if testMode == "m" else "li x25, 0xBAD00003"}

        csrrs x20, mepc, x0
        addi x20, x20, 4
        csrrw x0, mepc, x20
        bnez x30, _j_all_end_{returningInstruction}
        mret

        # Supervisor mode traps
        _j_s_trap_{returningInstruction}:
        {testJumpCode if testMode == "s" else "li x25, 0xBAD00001"}

        csrrs x20, sepc, x0
        addi x20, x20, 4
        csrrw x0, sepc, x20
        bnez x30, _j_goto_machine_mode_{returningInstruction}
        sret

        # Unused: user mode traps are no longer supported
        _j_u_trap_{returningInstruction}:
        {testJumpCode if testMode == "u" else "li x25, 0xBAD00000"}

        csrrs x20, uepc, x0
        addi x20, x20, 4
        csrrw x0, uepc, x20
        bnez x30, _j_goto_supervisor_mode_{returningInstruction}
        uret

        # Currently unused. Just jumps to _j_goto_machine_mode. If you actually
        # want to implement this, you'll likely need to reset sedeleg here
        # and then cause an exception with {returningInstruction} (based on my intuition. Try that first, but I could be missing something / just wrong)
        _j_goto_supervisor_mode_{returningInstruction}:
        j _j_goto_machine_mode_{returningInstruction}

        _j_goto_machine_mode_{returningInstruction}:
        li x30, 1 # This will cause us to branch to _j_all_end_{returningInstruction} in the machine trap handler, which we'll get into by invoking...
        {returningInstruction} # ... this instruction!

        # Run the actual tests!
        _j_t_begin_{returningInstruction}:
      """

      fromModeOptions = ["m", "s", "u"] if testMode == "m" else (["s", "u"] if testMode == "s" else ["u"])

      # We don't want to delegate our returning instruction. Otherwise, we'll have no way of getting
      # back to machine mode at the end! (and we need to be in machine mode to complete the tests)
      medelegMask = "0b1111111111110111" if returningInstruction == "ebreak" else "0b1111000011111111"

      # Set medeleg and mideleg
      lines += f"""
        csrr x18, medeleg
        li x9, {medelegMask if testMode == "s" or testMode == "u" else "0"}
        csrw medeleg, x9

        csrr x16, mideleg
        li x9, {"0xffffffff" if testMode == "s" or testMode == "u" else "0"}
        csrw mideleg, x9
      """

      f.write(lines)

      for fromMode in fromModeOptions:
        lines = ""
        
        # Code to bring us down to supervisor mode
        if fromMode == "s" or fromMode == "u":
          lines += f"""
            li x1, 0b110000000000
            csrrc x31, mstatus, x1
            li x1, 0b0100000000000
            csrrs x31, mstatus, x1

            auipc x1, 0
            addi x1, x1, 16 # x1 is now right after the mret instruction
            csrw mepc, x1
            mret

            # We're now in supervisor mode...
          """

        # Code to bring us down to user mode
        if fromMode == "u":
          lines += f"""

          li x1, 0b110000000000
          csrrc x31, sstatus, x1

          auipc x1, 0
          addi x1, x1, 16 # x1 is now right after the sret instruction
          csrw sepc, x1
          sret

          # We're now in user mode...
          """

        f.write(lines)
        for i in range(0,testCount):
          writeVectors(storecmd, returningInstruction)


      # Very end of test. Bring us back up to machine mode
      # We set x30 to 1, which will cause us to branch to _j_all_end in the
      # machine mode trap handler, before executing the mret instruction. This will
      # make us stay in machine mode.
      #
      # If we're currently in user mode, this will first bump us up to the supervisor mode
      # trap handler, which will call returningInstruction again before it's sret instruction,
      # bumping us up to machine mode
      #
      # Get into the trap handler by running returningInstruction (either an ecall or ebreak) 
      f.write(f"""
        li x30, 1
        li gp, 0
        {returningInstruction}
        _j_all_end_{returningInstruction}:

        # Reset trap handling csrs to old values
        csrw mtvec, x19
        csrw medeleg, x18
        csrw mideleg, x16
      """)

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
