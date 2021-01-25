#!/usr/bin/python3
##################################
#
# regression-wally.py
# David_Harris@Hmc.edu 25 January 2021
#
# Run a regression with multiple configurations and report any errors.
#
##################################

# edit this line to add more configurations
confignames = ["rv32ic", "rv64ic"]

import os

fail = 0

for config in confignames:
  logname = "wally_"+config+".log"
  cmd = "vsim -c >" + logname +" <<!\ndo wally-pipelined-batch.do ../config/" + config + "\n!\n"
  os.system(cmd)

  # check for success.  grep returns 0 if found, 1 if not found
  cmd = "grep 'All tests ran without failures' " + logname + "> /dev/null"
  grepval = os.system(cmd)
  if (grepval):
    fail = fail + 1
    print(logname+": failures detected")
  else:
    print(logname+": Success")

if (fail):
  print ("Regression failed with " +str(fail)+ " failed configurations")
else:
  print ("SUCCESS! All tests ran without failures")
