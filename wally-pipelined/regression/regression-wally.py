#!/usr/bin/python3
##################################
#
# regression-wally.py
# David_Harris@Hmc.edu 25 January 2021
# Modified by Jarred Allen <jaallen@g.hmc.edu>
#
# Run a regression with multiple configurations in parallel and exit with
# non-zero status code if an error happened, as well as printing human-readable
# output.
#
##################################
import sys,os

from collections import namedtuple
regressionDir = os.path.dirname(os.path.abspath(__file__))
os.chdir(regressionDir)
TestCase = namedtuple("TestCase", ['name', 'variant', 'cmd', 'grepstr'])
# name:     the name of this test configuration (used in printing human-readable
#           output and picking logfile names)
# cmd:      the command to run to test (should include the logfile as '{}', and
#           the command needs to write to that file)
# grepstr:  the string to grep through the log file for. The test succeeds iff
#           grep finds that string in the logfile (is used by grep, so it may
#           be any pattern grep accepts, see `man 1 grep` for more info).

# edit this list to add more test cases
configs = [
    TestCase(
        name="lints",
        variant="all",
        cmd="./lint-wally &> {}",
        grepstr="All lints run with no errors or warnings"
    )
]
def getBuildrootTC(short):
    INSTR_LIMIT = 100000 # multiple of 100000
    MAX_EXPECTED = 246000000
    if short:
        BRcmd="vsim > {} -c <<!\ndo wally-buildroot-batch.do "+str(INSTR_LIMIT)+" 1 0\n!"
        BRgrepstr=str(INSTR_LIMIT)+" instructions"
    else:
        BRcmd="vsim > {} -c <<!\ndo wally-buildroot-batch.do 0 1 0\n!"
        BRgrepstr=str(MAX_EXPECTED)+" instructions"
    return  TestCase(name="buildroot",variant="rv64gc",cmd=BRcmd,grepstr=BRgrepstr)

tc = TestCase(
      name="buildroot-checkpoint",
      variant="rv6gc",
      cmd="vsim > {} -c <<!\ndo wally-buildroot-batch.do 400100000 400000001 400000000\n!",
      grepstr="400100000 instructions")
configs.append(tc)

tests64gc = ["arch64i", "arch64priv", "arch64c",  "arch64m", "arch64d", "imperas64i", "imperas64f", "imperas64d", "imperas64p", "imperas64mmu", "imperas64m", "imperas64a",  "imperas64c"] # "wally64i", #,  "testsBP64"] 
for test in tests64gc:
  tc = TestCase(
        name=test,
        variant="rv64gc",
        cmd="vsim > {} -c <<!\ndo wally-pipelined-batch.do rv64gc "+test+"\n!",
        grepstr="All tests ran without failures")
  configs.append(tc)
tests32gc = ["arch32i", "arch32priv", "arch32c",  "arch32m", "arch32f", "imperas32i", "imperas32f", "imperas32p", "imperas32mmu", "imperas32m", "imperas32a",  "imperas32c"]  #"wally32i", 
for test in tests32gc:
  tc = TestCase(
        name=test,
        variant="rv32gc",
        cmd="vsim > {} -c <<!\ndo wally-pipelined-batch.do rv32gc "+test+"\n!",
        grepstr="All tests ran without failures")
  configs.append(tc)

tests32ic = ["arch32i", "arch32c"] 
for test in tests32ic:
  tc = TestCase(
        name=test,
        variant="rv32ic",
        cmd="vsim > {} -c <<!\ndo wally-pipelined-batch.do rv32ic "+test+"\n!",
        grepstr="All tests ran without failures")
  configs.append(tc)


import os
from multiprocessing import Pool, TimeoutError

def search_log_for_text(text, logfile):
    """Search through the given log file for text, returning True if it is found or False if it is not"""
    grepcmd = "grep -e '%s' '%s' > /dev/null" % (text, logfile)
    return os.system(grepcmd) == 0

def run_test_case(config):
    """Run the given test case, and return 0 if the test suceeds and 1 if it fails"""
    logname = "logs/"+config.variant+"_"+config.name+".log"
    cmd = config.cmd.format(logname)
    print(cmd)
    os.chdir(regressionDir)
    os.system(cmd)
    if search_log_for_text(config.grepstr, logname):
        print("%s_%s: Success" % (config.variant, config.name))
        return 0
    else:
        print("%s_%s: Failures detected in output" % (config.variant, config.name))
        print("  Check %s" % logname)
        return 1

def main():
    """Run the tests and count the failures"""
    global configs
    try:
        os.chdir(regressionDir)
        os.mkdir("logs")
    except:
        pass

    if '-makeTests' in sys.argv:
        os.chdir(regressionDir)
        os.system('./make-tests.sh | tee ./logs/make-tests.log')

    if '-all' in sys.argv:
        TIMEOUT_DUR = 20*3600 # seconds
        configs.append(getBuildrootTC(short=False))
    elif '-buildroot' in sys.argv:
        TIMEOUT_DUR = 20*3600 # seconds
        configs=[getBuildrootTC(short=False)]
    else:
        TIMEOUT_DUR = 5*60 # seconds
        configs.append(getBuildrootTC(short=True))

    # Scale the number of concurrent processes to the number of test cases, but
    # max out at a limited number of concurrent processes to not overwhelm the system
    with Pool(processes=min(len(configs),25)) as pool:
       num_fail = 0
       results = {}
       for config in configs:
           results[config] = pool.apply_async(run_test_case,(config,))
       for (config,result) in results.items():
           try:
             num_fail+=result.get(timeout=TIMEOUT_DUR)
           except TimeoutError:
             num_fail+=1
             print("%s: Timeout - runtime exceeded %d seconds" % (config.name, TIMEOUT_DUR))

    # Count the number of failures
    if num_fail:
        print("Regression failed with %s failed configurations" % num_fail)
        # Remind the user to try `make allclean`, since it may be needed if test
        # cases have changed
        print("Reminder: have you run `make allclean`?")
    else:
        print("SUCCESS! All tests ran without failures")
    return num_fail

if __name__ == '__main__':
    exit(main())
