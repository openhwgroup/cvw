#!/usr/bin/python3
##################################
#
# regression-wally.py
# David_Harris@Hmc.edu 25 January 2021
#
# Run a regression with multiple configurations in parallel and exit with non-zero status if an error happened
#
##################################

from collections import namedtuple
# name:     the name of this test configuration/script
# cmd:      the command to run to test (should include the logfile as {})
# grepstr:  the string to grep through the log file for, success iff grep finds that string
Config = namedtuple("Config", ['name', 'cmd', 'grepstr'])

# edit this list to add more configurations
configs = [
    Config(
        name="busybear",
        cmd="vsim -do wally-busybear-batch.do -c > {}",
        grepstr="# loaded 40000 instructions"
    ),
    Config(
        name="buildroot",
        cmd="vsim -do wally-buildroot-batch.do -c > {}",
        grepstr="# loaded 100000 instructions"
    ),
    Config(
        name="rv32ic",
        cmd="vsim > {} -c <<!\ndo wally-pipelined-batch.do ../config/rv32ic rv32ic\n!",
        grepstr="All tests ran without failures"
    ),
    Config(
        name="rv64ic",
        cmd="vsim > {} -c <<!\ndo wally-pipelined-batch.do ../config/rv64ic rv64ic\n!",
        grepstr="All tests ran without failures"
    ),
    Config(
        name="lints",
        cmd="../lint-wally > {}",
        grepstr="All lints run with no errors or warnings"
    ),
]

import multiprocessing, os

fail = 0

def search_log_for_text(text, logfile):
    """Search through the given log file for text, returning True if it is found or False if it is not"""
    grepcmd = "grep -e '%s' '%s' > /dev/null" % (text, logfile)
    return os.system(grepcmd) == 0

def test_config(config, print_res=True):
    """Run the given config, and return 0 if it suceeds and 1 if it fails"""
    logname = "wally_"+config.name+".log"
    cmd = config.cmd.format(logname)
    print(cmd)
    os.system(cmd)
    # check for success.  grep returns 0 if found, 1 if not found
    passed = search_log_for_text(config.grepstr, logname)
    if passed:
        if print_res:print(logname+": Success")
        return 0
    else:
        if print_res:print(logname+": failures detected")
        return 1

# Run the tests and count the failures
pool = multiprocessing.Pool(min(len(configs), 12))
fail = sum(pool.map(test_config, configs))

if (fail):
    print("Regression failed with " +str(fail)+ " failed configurations")
    print("Reminder: have you run `make allclean`?")
    exit(1)
else:
    print("SUCCESS! All tests ran without failures")
    exit(0)
