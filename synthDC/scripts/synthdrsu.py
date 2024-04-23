import sys,os,shutil,multiprocessing
from multiprocessing import Pool, TimeoutError
from collections import namedtuple

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

regressionDir = os.path.dirname(os.path.join(os.path.abspath(__file__),os.pardir))
Job = namedtuple("Job", ['name', 'frequency', 'cmd', 'grepstr', 'design'])
derivedconfigs = [
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
    "f_ieee_div_4_4i_rv64gc", "f_ieee_div_4_4_rv32gc", "f_ieee_div_4_4_rv64gc",
    "fd_ieee_div_2_8_rv64gc", "fd_ieee_div_2_8_rv32gc", "fd_ieee_div_2_8i_rv64gc",
    "fd_ieee_div_2_8i_rv32gc",
    "fdq_ieee_div_2_8_rv64gc", "fdq_ieee_div_2_8_rv32gc", "fdq_ieee_div_2_8i_rv64gc",
    "fdq_ieee_div_2_8i_rv32gc",
    "f_ieee_div_2_8_rv64gc", "f_ieee_div_2_8_rv32gc", "f_ieee_div_2_8i_rv64gc",
    "f_ieee_div_2_8i_rv32gc"
]

derivedconfigsmdu = [
    "idiv_bitspercycle_16_rv32gc",
    "idiv_bitspercycle_16_rv64gc",
    "idiv_bitspercycle_1_rv32gc",
    "idiv_bitspercycle_1_rv64gc",
    "idiv_bitspercycle_2_rv32gc",
    "idiv_bitspercycle_2_rv64gc",
    "idiv_bitspercycle_4_rv32gc",
    "idiv_bitspercycle_4_rv64gc",
    "idiv_bitspercycle_8_rv32gc",
    "idiv_bitspercycle_8_rv64gc"
]

def search_log_for_text(text, logfile):
    """Search through the given log file for text, returning True if it is found or False if it is not"""
    print(os.getcwd())
    grepcmd = "grep -e '%s' '../%s' > /dev/null" % (text, logfile)
    return os.system(grepcmd) == 0

def run_synth_job(config):
    """Run the given test case, and return 0 if the test suceeds and 1 if it fails"""
    logname = f"runs/{config.design}_{config.name}_orig_tsmc28nm_{config.frequency}_MHz/synth.out"
    cmd = config.cmd
#    print(cmd)
    os.system(cmd)
    if search_log_for_text(config.grepstr, logname):
        print(f"{bcolors.OKGREEN}%s_%s: Success{bcolors.ENDC}" % (config.name, config.frequency))
        return 0
    else:
        print(f"{bcolors.FAIL}%s_%s: Failures detected in output{bcolors.ENDC}" % (config.name, config.frequency))
        print("  Check %s" % logname)
        return 1

def main():

    TIMEOUT_DUR = 30*7200 # seconds
    """Run the tests and count the failures"""
    global derivedconfigs, coverage
    configs=[]
    try:
        os.chdir(regressionDir)
        os.mkdir("logs")
    except:
        pass

    for config in derivedconfigs:
      drsu_5000 = Job(
          name=config,
          design="drsu",
          cmd=f"make -C $WALLY/synthDC synth DESIGN=drsu TECH=tsmc28 CONFIG={config} FREQ=6000 > /dev/null", 
          grepstr="Optimization",
          frequency=6000
      )

      drsu_100 = Job(
          name=config,
          design="drsu",
          cmd=f"make -C $WALLY/synthDC synth DESIGN=drsu TECH=tsmc28 CONFIG={config} FREQ=100 > /dev/null", 
          grepstr="Optimization", 
          frequency=100
      )
      configs.append(drsu_5000)
      configs.append(drsu_100)

    for config in derivedconfigsmdu:
      mdu_5000 = Job(
          name=config,
          design="mdudiv",
          cmd=f"make -C $WALLY/synthDC synth DESIGN=mdudiv TECH=tsmc28 CONFIG={config} FREQ=6000 > /dev/null", 
          grepstr="Optimization",
          frequency=6000
      )

      mdu_100 = Job(
          name=config,
          design="mdudiv",
          cmd=f"make -C $WALLY/synthDC synth DESIGN=mdudiv TECH=tsmc28 CONFIG={config} FREQ=100 > /dev/null", 
          grepstr="Optimization", 
          frequency=100
      )
      configs.append(mdu_5000)
      configs.append(mdu_100)


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