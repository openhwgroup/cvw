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

import multiprocessing, os

fail = 0

def test_config(config, print_res=True):
  """Run the given config, and return 0 if it suceeds and 1 if it fails"""
  logname = "wally_"+config+".log"
  cmd = "vsim -c >" + logname +" <<!\ndo wally-pipelined-batch-parallel.do ../config/" + config + " " + config + "\n!\n"
  os.system(cmd)

  # check for success.  grep returns 0 if found, 1 if not found
  cmd = "grep 'All tests ran without failures' " + logname + "> /dev/null"
  grepval = os.system(cmd)
  if (grepval):
    if print_res:print(logname+": failures detected")
    return 1
  else:
    if print_res:print(logname+": Success")
    return 0

pool = multiprocessing.Pool(min(len(confignames), 12))
fail = sum(pool.map(test_config, confignames))

if (fail):
  print ("Regression failed with " +str(fail)+ " failed configurations")
  exit(1)
else:
  print ("SUCCESS! All tests ran without failures")
  exit(0)
