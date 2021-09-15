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

from collections import namedtuple
TestCase = namedtuple("TestCase", ['name', 'cmd', 'grepstr'])
# name:     the name of this test configuration (used in printing human-readable
#           output and picking logfile names)
# cmd:      the command to run to test (should include the logfile as '{}', and
#           the command needs to write to that file)
# grepstr:  the string to grep through the log file for. The test succeeds iff
#           grep finds that string in the logfile (is used by grep, so it may
#           be any pattern grep accepts, see `man 1 grep` for more info).

# edit this list to add more test cases
configs = [
    #TestCase(
    #    name="busybear",
    #    cmd="vsim -do wally-busybear-batch.do -c > {}",
    #    grepstr="loaded 100000 instructions"
    #),
    TestCase(
        name="buildroot",
        cmd="vsim -do wally-buildroot-batch.do -c > {}",
        grepstr="loaded 6000 instructions"
    ),
    TestCase(
        name="arch64",
        cmd="vsim > {} -c <<!\ndo wally-arch.do ../config/rv64ic rv64ic\n!",
        grepstr="All tests ran without failures"
    ),
    TestCase(
        name="arch32",
        cmd="vsim > {} -c <<!\ndo wally-arch.do ../config/rv32ic rv32ic\n!",
        grepstr="All tests ran without failures"
    ),
    TestCase(
        name="rv32ic",
        cmd="vsim > {} -c <<!\ndo wally-pipelined-batch.do ../config/rv32ic rv32ic\n!",
        grepstr="All tests ran without failures"
    ),
    TestCase(
        name="rv64ic",
        cmd="vsim > {} -c <<!\ndo wally-pipelined-batch.do ../config/rv64ic rv64ic\n!",
        grepstr="All tests ran without failures"
    ),
    TestCase(
        name="lints",
        cmd="../lint-wally &> {}",
        grepstr="All lints run with no errors or warnings"
    ),
]

import os
from multiprocessing import Pool, TimeoutError

def search_log_for_text(text, logfile):
    """Search through the given log file for text, returning True if it is found or False if it is not"""
    grepcmd = "grep -e '%s' '%s' > /dev/null" % (text, logfile)
    return os.system(grepcmd) == 0

def run_test_case(config):
    """Run the given test case, and return 0 if the test suceeds and 1 if it fails"""
    logname = "regression_logs/wally_"+config.name+".log"
    cmd = config.cmd.format(logname)
    print(cmd)
    os.system(cmd)
    if search_log_for_text(config.grepstr, logname):
        print("%s: Success" % config.name)
        return 0
    else:
        print("%s: Failures detected in output" % config.name)
        print("  Check %s" % logname)
        return 1

def main():
    """Run the tests and count the failures"""
    # Scale the number of concurrent processes to the number of test cases, but
    # max out at 12 concurrent processes to not overwhelm the system
    TIMEOUT_DUR = 600 # seconds
    try:
        os.mkdir("regression_logs")
    except:
        pass
    with Pool(processes=min(len(configs),12)) as pool:
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
