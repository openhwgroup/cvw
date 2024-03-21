import os
from multiprocessing import Pool, TimeoutError


Job = namedtuple("Job", ['config', 'frequency', 'cmd', 'grepstr'])
configs = [
    "fd_ieee_div_2_1i_rv32gc", "fd_ieee_div_2_1i_rv64gc", "fd_ieee_div_2_1_rv32gc",
    "fd_ieee_div_2_1_rv64gc", "fd_ieee_div_2_2i_rv32gc", "fd_ieee_div_2_2i_rv64gc",
    "fd_ieee_div_2_2_rv32gc", "fd_ieee_div_2_2_rv64gc", "fd_ieee_div_2_4i_rv32gc",
    "fd_ieee_div_2_4i_rv64gc", "fd_ieee_div_2_4_rv32gc", "fd_ieee_div_2_4_rv64gc",
    "fd_ieee_div_4_1i_rv32gc", "fd_ieee_div_4_1i_rv64gc", "fd_ieee_div_4_1_rv32gc",
    "fd_ieee_div_4_1_rv64gc", "fd_ieee_div_4_2i_rv32gc", "fd_ieee_div_4_2i_rv64gc",
    "fd_ieee_div_4_2_rv32gc", "fd_ieee_div_4_2_rv64gc", "fd_ieee_div_4_4i_rv32gc",
    "fd_ieee_div_4_4i_rv64gc", "fd_ieee_div_4_4_rv32gc", "fd_ieee_div_4_4_rv64gc",
    "fdq_ieee_div_2_1i_rv32gc", "fdq_ieee_div_2_1i_rv64gc", "fdq_ieee_div_2_1_rv32gc",
    "fdq_ieee_div_2_1_rv64gc", "fdq_ieee_div_2_2i_rv32gc", "fdq_ieee_div_2_2i_rv64gc",
    "fdq_ieee_div_2_2_rv32gc", "fdq_ieee_div_2_2_rv64gc", "fdq_ieee_div_2_4i_rv32gc",
    "fdq_ieee_div_2_4i_rv64gc", "fdq_ieee_div_2_4_rv32gc", "fdq_ieee_div_2_4_rv64gc",
    "fdq_ieee_div_4_1i_rv32gc", "fdq_ieee_div_4_1i_rv64gc", "fdq_ieee_div_4_1_rv32gc",
    "fdq_ieee_div_4_1_rv64gc", "fdq_ieee_div_4_2i_rv32gc", "fdq_ieee_div_4_2i_rv64gc",
    "fdq_ieee_div_4_2_rv32gc", "fdq_ieee_div_4_2_rv64gc", "fdq_ieee_div_4_4i_rv32gc",
    "fdq_ieee_div_4_4i_rv64gc", "fdq_ieee_div_4_4_rv32gc", "fdq_ieee_div_4_4_rv64gc",
    "f_ieee_div_2_1i_rv32gc", "f_ieee_div_2_1i_rv64gc", "f_ieee_div_2_1_rv32gc",
    "f_ieee_div_2_1_rv64gc", "f_ieee_div_2_2i_rv32gc", "f_ieee_div_2_2i_rv64gc",
    "f_ieee_div_2_2_rv32gc", "f_ieee_div_2_2_rv64gc", "f_ieee_div_2_4i_rv32gc",
    "f_ieee_div_2_4i_rv64gc", "f_ieee_div_2_4_rv32gc", "f_ieee_div_2_4_rv64gc",
    "f_ieee_div_4_1i_rv32gc", "f_ieee_div_4_1i_rv64gc", "f_ieee_div_4_1_rv32gc",
    "f_ieee_div_4_1_rv64gc", "f_ieee_div_4_2i_rv32gc", "f_ieee_div_4_2i_rv64gc",
    "f_ieee_div_4_2_rv32gc", "f_ieee_div_4_2_rv64gc", "f_ieee_div_4_4i_rv32gc",
    "f_ieee_div_4_4i_rv64gc", "f_ieee_div_4_4_rv32gc", "f_ieee_div_4_4_rv64gc"
]

def search_log_for_text(text, logfile):
    """Search through the given log file for text, returning True if it is found or False if it is not"""
    grepcmd = "grep -e '%s' '%s' > /dev/null" % (text, logfile)
    return os.system(grepcmd) == 0

def run_synth_job(config):
    """Run the given test case, and return 0 if the test suceeds and 1 if it fails"""
    logname = "logs/"+config.variant+"_"+config.name+".log"
    cmd = config.cmd
#    print(cmd)
    os.system(cmd)
    if search_log_for_text(config.grepstr, logname):
        print(f"{bcolors.OKGREEN}%s_%s: Success{bcolors.ENDC}" % (config.variant, config.name))
        return 0
    else:
        print(f"{bcolors.FAIL}%s_%s: Failures detected in output{bcolors.ENDC}" % (config.variant, config.name))
        print("  Check %s" % logname)
        return 1

def main():
    """Run the tests and count the failures"""
    global configs, coverage
    try:
        os.chdir(regressionDir)
        os.mkdir("logs")
    except:
        pass

    for config in configs:
        synthjob_5000 = Job(
            name=config,
            cmd=f"make -C $WALLY/synthDC synth DESIGN=drsu TECH=tsmc28 CONFIG={config} FREQ=5000 > /dev/null" 
            grepstr="All Tests completed with          0 errors" # change this
        )

        synthjob_100 = Job(
            name=config,
            cmd=f"make -C $WALLY/synthDC synth DESIGN=drsu TECH=tsmc28 CONFIG={config} FREQ=100 > /dev/null" 
            grepstr="All Tests completed with          0 errors" # change this
        )
        configs.append(synthjob_5000)
        configs.append(synthjob_100)


    # Scale the number of concurrent processes to the number of test cases, but
    # max out at a limited number of concurrent processes to not overwhelm the system
    with Pool(processes=min(len(configs),multiprocessing.cpu_count())) as pool:
       num_fail = 0
       results = {}
       for config in configs:
           results[config] = pool.apply_async(run_synth_job,(config,))
       for (config,result) in results.items():
           try:
             num_fail+=result.get(timeout=TIMEOUT_DUR)
           except TimeoutError:
             num_fail+=1
             print(f"{bcolors.FAIL}%s_%s: Timeout - runtime exceeded %d seconds{bcolors.ENDC}" % (config.variant, config.name, TIMEOUT_DUR))

    # Count the number of failures
    if num_fail:
        print(f"{bcolors.FAIL}Regression failed with %s failed configurations{bcolors.ENDC}" % num_fail)
    else:
        print(f"{bcolors.OKGREEN}SUCCESS! All tests ran without failures{bcolors.ENDC}")
    return num_fail

if __name__ == '__main__':
    exit(main())