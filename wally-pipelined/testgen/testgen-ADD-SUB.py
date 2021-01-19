# testgen-ADD-SUB.py
#
# David_Harris@hmc.edu 19 January 2021
#
# Generate directed and random test vectors for RISC-V Design Validation.

# libraries
#import bitstream as bs

#corners = [0, 1, 2, 0xFF, 0x624B3E97CC52DD14, 0x7FFFFFFFFFFFFFFE, 0x7FFFFFFFFFFFFFFF, 
#           0x8000000000000000, 0x8000000000000001, 0xC365DDEB9173AB42, 0xFFFFFFFFFFFFFFFE, 0xFFFFFFFFFFFFFFFF]
corners = [0, 1, 2, 255]

testname = "ADD-SUB"
fname = "WALLY-" + testname
testnum = 0;



 
 
    # Testcase 0:  rs1:x31(0x10fd3dedadea5195), rs2:x16(0xdf7f3844121bcc23), result rd:x1(0xf07c7631c0061db8)
 #   li  x16, MASK_XLEN(0xdf7f3844121bcc23)
    #li  x31, MASK_XLEN(0x10fd3dedadea5195)
  #  add x1, x31, x16
   # sd x1, 0(x6)
    #RVTEST_IO_ASSERT_GPR_EQ(x7, x1, 0xf07c7631c0061db8) 


f = open(fname, "w")
for a in corners:
  for b in corners:
    tc = "# Testcase " + str(testnum
    f.write(tc)
    line = "li x1, MASK_XLEN(" + str(a) + ")"
    f.write(line)
    testnum = testnum+1
f.close()