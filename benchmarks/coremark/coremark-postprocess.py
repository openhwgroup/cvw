#!/usr/bin/env python
#########################################################
#
# coremark postprocessing script
#
# Author: Kip Macsai-Goren <kmacsaigoren@g.hmc.edu>
#
# Created 2022-09-25
#
# Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
# modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software
# is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
# OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
##################################################

logFile = "../../benchmarks/coremark/work/coremark.sim.log"

with open(logFile, "r") as logRead:
    logLines = logRead.readlines()

for lineNum in range(len(logLines)):
    contents = logLines[lineNum].lower().split()
    if "branches" in contents and "miss" in contents:
        branchMisses = int(contents[-1])
    elif "branches" in contents:
        branchesTot = int(contents[-1])
        branchLineNum = lineNum + 2

logLines.insert(branchLineNum, "# Branches Miss/Total ratio " + str(branchMisses / branchesTot) + "\n")

with open(logFile, "w") as logWrite:
    logWrite.writelines(logLines)





