#!/usr/bin/env python3
# embench_arch_sweep.py
# David_Harris@hmc.edu 16 November 2023
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

# Run embench on a variety of architectures and collate results

import os
from datetime import datetime
import re
import collections

archs = ["rv32i_zicsr", "rv32im_zicsr", "rv32imc_zicsr", "rv32imc_zba_zbb_zbc_zbs_zicsr", "rv32imafdc_zba_zbb_zbc_zbs_zicsr"]

def calcgeomean(d, arch):
    progs = ["aha-mont64", "crc32", "cubic", "edn", "huffbench", "matmult-int", "minver", "nbody", "nettle-aes", "nettle-sha256", "nsichneu", "picojpeg", "qrduino", "sglib-combined", "slre", "st", "statemate", "ud", "wikisort"]
    result = 1.0
    for p in progs:
        #val = d[arch][p]
        val = d[arch].get(p, 1.0)
        result = result *float(val)
    result = pow(result, (1.0/float(len(progs))))
    return result

def tabulate_arch_sweep(directory):
    for case in ["wallySizeOpt_size", "wallySpeedOpt_size",  "wallySizeOpt_speed", "wallySpeedOpt_speed"]:
        print(case)
        d = collections.defaultdict(dict)
        for arch in archs:
            file = case+"_"+arch+".json"
            file_path = os.path.join(directory, file)
            lines = []
            try:
                f = open(file_path, "r")
                lines = f.readlines()
            except:
                f.close()
                #print(file_path+" does not exist")
            for line in lines:
                #print("File: "+file+" Line: "+line)
                #p = re.compile('".*" : .*,')
                p = r'"([^"]*)" : ([^,\n]+)'
                match = re.search(p, line)
                if match:
                    prog = match.group(1)
                    result = match.group(2);
                    d[arch][prog] = result;
                    #print(match.group(1)+" " + match.group(2))
            f.close()
        for arch in [""] + archs:
            print (arch, end="\t")
        print("")
        for prog in d[archs[0]]:
            print(prog, end="\t")
            for arch in archs:
                entry = d[arch].get(prog, "n/a");
                print (entry, end="\t")
            print("")
        print("New geo mean", end="\t")
        for arch in archs:
            geomean = calcgeomean(d, arch)
            print(geomean, end="\t")
        print("\n\n")
 
def run_arch_sweep():
    # make a folder whose name depends on the date
    # Get current date
    current_date = datetime.now()
    # Format date as a string in the format YYYYMMDD
    date_string = current_date.strftime('%Y%m%d_%H%M%S')
    dir = "run_"+date_string
    # Create a directory with the date string as its name
    os.mkdir(dir)

    # make a directory with the current date as its name 

    # sweep the runs and save the results in the run directory
    for arch in archs:
        os.system("make clean")
        os.system("make run ARCH="+arch)
        for res in ["SizeOpt_size", "SizeOpt_speed", "SpeedOpt_size", "SpeedOpt_speed"]:
            os.system("mv -f wally"+res+".json "+dir+"/wally"+res+"_"+arch+".json")
    return dir

directory = run_arch_sweep()
#directory = "run_20231120_072037-caches"
tabulate_arch_sweep(directory)