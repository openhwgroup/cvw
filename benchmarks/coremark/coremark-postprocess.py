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
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
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
    
    if "d-cache" in contents and "misses" in contents:
        dCacheMisses = int(contents[-1])
    elif "d-cache" in contents:
        dCacheAccess = int(contents[-1])
        dCacheLineNum = lineNum + 2

    if "i-cache" in contents and "misses" in contents:
        ICacheMisses = int(contents[-1])
    elif "i-cache" in contents:
        ICacheAccess = int(contents[-1])
        ICacheLineNum = lineNum + 2

# need to add the number of previously added lines to the line number so that they stay in the intedned order.
logLines.insert(dCacheLineNum, "# D-cache Hits " + str(dCacheAccess - dCacheMisses) + "\n")
logLines.insert(dCacheLineNum+1, "# D-cache Miss Rate " + str(dCacheMisses / dCacheAccess) + "\n")
logLines.insert(dCacheLineNum+2, "# D-cache Hit Rate " + str((dCacheAccess - dCacheMisses) / dCacheAccess) + "\n")

logLines.insert(ICacheLineNum+3, "# I-cache Hits " + str(ICacheAccess - ICacheMisses) + "\n")
logLines.insert(ICacheLineNum+4, "# I-cache Miss Rate " + str(ICacheMisses / ICacheAccess) + "\n")
logLines.insert(ICacheLineNum+5, "# I-cache Hit Rate " + str((ICacheAccess - ICacheMisses) / ICacheAccess) + "\n")

logLines.insert(branchLineNum+6, "# Branches Miss/Total ratio " + str(branchMisses / branchesTot) + "\n")


with open(logFile, "w") as logWrite:
    logWrite.writelines(logLines)





