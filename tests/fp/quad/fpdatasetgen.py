#!/usr/bin/env python3

from fp_dataset import *
#coverpoints=ibm_b1(128, 128, 'fadd.q', 2) #ibm_b1(flen, iflen, opcode, ops)
coverpoints=ibm_b2(128,128,'fadd.q',2) #ibm_b2(flen, iflen, opcode, ops, int_val = 100, seed = -1)
#coverpoints=ibm_b2(32,32,'fadd.s',2) #ibm_b2(flen, iflen, opcode, ops,seed = -1)
#print(coverpoints)
#quad_precision_hex = "0x3ff00000000000000000000000000001"  # Example quad precision hexadecimal value
#quad_precision_dec = fields_dec_converter(128, quad_precision_hex)
#print(quad_precision_dec)
for cvpts in coverpoints:
    print(cvpts)
    print("\n")
print(len(coverpoints))
