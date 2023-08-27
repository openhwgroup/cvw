"""
wrapperGen.py

kekim@hmc.edu

script that generates top-level wrappers for verilog modules to synthesize
"""

import argparse
import os

#create argument parser
parser = argparse.ArgumentParser()

parser.add_argument("fin")

args=parser.parse_args()

fin = open(args.fin, "r")

lines = fin.readlines()

# keeps track of what line number the module header begins
lineModuleStart = 0

# keeps track of what line number the module header ends
lineModuleEnd = 0

# keeps track of module name
moduleName = ""

# string that will keep track of the running module header
buf = "`include \"config.vh\"\n`include \"parameter-defs.vh\"\nimport cvw::*;\n"

# are we writing into the buffer
writeBuf=False

index=0

# string copy logic
for l in lines:
    if l.find("module") == 0:
        lineModuleStart = index
        moduleName = l.split()[1]
        writeBuf = True
        buf += f"module {moduleName}wrapper (\n"
        continue
    if (writeBuf):
        buf += l
    if l.find (");") == 0:
        lineModuleEnd = index
        break
    index+=1

# post-processing buffer: add DUT and endmodule lines
buf += f"\t{moduleName} #(P) dut(.*);\nendmodule"



print(buf)