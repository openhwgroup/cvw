#!/usr/bin/env python3
# Madeleine Masser-Frye mmasserfrye@hmc.edu 1/2023

import argparse
import subprocess, os, shutil
import re
from multiprocessing import Pool
from datetime import datetime

def extract_datetime(s):
    match = re.search(r'\d{4}-\d{2}-\d{2}-\d{2}-\d{2}', s)
    if match:
        return datetime.strptime(match.group(), "%Y-%m-%d-%H-%M")
    else:
        return datetime.min  # or raise an error
    

def runSynth(config, mod, tech, freq, maxopt, usesram, cores):
    global pool
    command = f"make synth DESIGN=wallypipelinedcore CONFIG={config} MOD={mod} TECH={tech} DRIVE=FLOP FREQ={freq} MAXOPT={maxopt} USESRAM={usesram} MAXCORES={cores}"
    subprocess.run([command],shell=True)
    
    gateFolder = os.path.join(os.environ['WALLY'],"gate")
    currDir = "./runs/"
    folders = [name for name in os.listdir(currDir) if os.path.isdir(os.path.join(currDir, name))]
    sorted_folders = sorted(folders, key=extract_datetime, reverse=True)
    
    folderOfInterest = os.path.join(currDir, sorted_folders[0], "mapped")
    shutil.copytree(folderOfInterest, gateFolder)

    # Adding link to tech lib for simulation 
    techLibSimModel = os.environ['LIBRARY_SIM_PATH']
    techLibSimModelLink = os.path.join(gateFolder, "techLib.v" )
    os.symlink(techLibSimModel,techLibSimModelLink)

if __name__ == '__main__':

    techs = ['sky130', 'sky90', 'tsmc28', 'tsmc28psyn', 'nangate45']
    #allConfigs = ['rv32gc', 'rv32imc', 'rv64gc', 'rv64imc', 'rv32e', 'rv32i', 'rv64i']
    freqVaryPct = [-20, -12, -8, -6, -4, -2, 0, 2, 4, 6, 8, 12, 20]
#    freqVaryPct = [-20, -10, 0, 10, 20]

    pool = Pool()

    parser = argparse.ArgumentParser()

    parser.add_argument("-s", "--freqsweep", type=int, help = "Synthesize wally with target frequencies at given MHz and +/- 2, 4, 6, 8 %%")
    parser.add_argument("-c", "--cores", type=int, help = "Maximum parallel cores to use in the synthesis flow. ")
    parser.add_argument("-v", "--version", help = "Configuration of wally")
    parser.add_argument("-t", "--targetfreq", type=int, help = "Target frequency")
    parser.add_argument("-e", "--tech", choices=techs, help = "Technology")
    parser.add_argument("-o", "--maxopt", action='store_true', help = "Turn on MAXOPT")
    parser.add_argument("-r", "--usesram", action='store_true', help = "Use SRAM modules")

    args = parser.parse_args()

    tech = 'nangate45'
    maxopt = int(args.maxopt)
    usesram = int(args.usesram)
    mod = 'orig'
    cores = int(args.cores)

    defaultfreq = 500 if tech == 'sky90' else 1500
    freq = args.targetfreq if args.targetfreq else defaultfreq
    config = args.version

    runSynth(config, mod, tech, freq, maxopt, usesram, cores)
