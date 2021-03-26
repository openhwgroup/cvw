#!/usr/bin/python3
##################################
#
# regression-wally.py
# David_Harris@Hmc.edu 25 January 2021
#
# Run a regression with multiple configurations in parallel and exit with non-zero status if an error happened
#
##################################

# edit this line to add more configurations
confignames = ["rv32ic", "rv64ic", "busybear"]

import multiprocessing, os

fail = 0

def search_log_for_text(text, logfile):
    """Search through the given log file for text, returning True if it is found or False if it is not"""
    grepcmd = "grep -e '%s' '%s' > /dev/null" % (text, logfile)
    return os.system(grepcmd) == 0

def test_config(config, print_res=True):
  """Run the given config, and return 0 if it suceeds and 1 if it fails"""
  logname = "wally_"+config+".log"
  if config == "busybear":
    # Handle busybear separately
    cmd = "vsim -do wally-busybear-batch.do -c >" + logname
    os.system(cmd)
    # check for success.  grep returns 0 if found, 1 if not found
    passed = search_log_for_text("# loaded 800000 instructions", logname)
  else:
    # Any other configuration loads that name from the config folder and runs vsim
    cmd = "vsim -c >" + logname +" <<!\ndo wally-pipelined-batch.do ../config/" + config + " " + config + "\n!\n"
    print(cmd)
    os.system(cmd)
    # check for success.  grep returns 0 if found, 1 if not found
    passed = search_log_for_text("All tests ran without failures", logname)
  if passed:
    if print_res:print(logname+": Success")
    return 0
  else:
    if print_res:print(logname+": failures detected")
    return 1

# Run the tests and count the failures
pool = multiprocessing.Pool(min(len(confignames), 12))
fail = sum(pool.map(test_config, confignames))

if (fail):
  print ("Regression failed with " +str(fail)+ " failed configurations")
  exit(1)
else:
  print ("SUCCESS! All tests ran without failures")
  exit(0)
