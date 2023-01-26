#!/usr/bin/python3
# Madeleine Masser-Frye mmasserfrye@hmc.edu 6/22

import subprocess
from multiprocessing import Pool
import argparse

def runSynth(config, mod, tech, freq, maxopt):
    global pool
    command = "make synth DESIGN=wallypipelinedcore CONFIG={} MOD={} TECH={} DRIVE=FLOP FREQ={} MAXOPT={} MAXCORES=1".format(config, mod, tech, freq, maxopt)
    pool.map(mask, [command])

def mask(command):
    subprocess.Popen(command, shell=True)


if __name__ == '__main__':
    
    techs = ['sky90', 'tsmc28']
    allConfigs = ['rv32gc', 'rv32ic', 'rv64gc', 'rv64ic', 'rv32e', 'rv32i', 'rv64i']
    freqVaryPct = [-20, -12, -8, -6, -4, -2, 0, 2, 4, 6, 8, 12, 20]

    pool = Pool()

    parser = argparse.ArgumentParser()

    parser.add_argument("-s", "--freqsweep", type=int, help = "Synthesize wally with target frequencies at given MHz and +/- 2, 4, 6, 8 %%")
    parser.add_argument("-c", "--configsweep", action='store_true', help = "Synthesize wally with configurations 32e, 32ic, 64ic, 32gc, and 64gc")
    parser.add_argument("-f", "--featuresweep", action='store_true', help = "Synthesize wally with features turned off progressively to visualize critical path")

    parser.add_argument("-v", "--version", choices=allConfigs, help = "Configuration of wally")
    parser.add_argument("-t", "--targetfreq", type=int, help = "Target frequncy")
    parser.add_argument("-e", "--tech", choices=techs, help = "Technology")
    parser.add_argument("-o", "--maxopt", action='store_true', help = "Turn on MAXOPT")

    args = parser.parse_args()

    tech = args.tech if args.tech else 'sky90'
    defaultfreq = 3000 if tech == 'sky90' else 10000
    freq = args.targetfreq if args.targetfreq else defaultfreq
    maxopt = int(args.maxopt)
    mod = 'orig' # until memory integrated

    if args.freqsweep:
        sc = args.freqsweep
        config = args.version if args.version else 'rv32e'
        for freq in [round(sc+sc*x/100) for x in freqVaryPct]: # rv32e freq sweep
            runSynth(config, mod, tech, freq, maxopt)
    if args.configsweep:
        for config in ['rv32i', 'rv64gc', 'rv64i', 'rv32gc', 'rv32ic', 'rv32e']: #configs
            runSynth(config, mod, tech, freq, maxopt)
    if args.featuresweep:
        config = args.version if args.version else 'rv64gc'
        for mod in ['FPUoff', 'noMulDiv', 'noPriv', 'PMP0', 'PMP16']: # rv64gc path variations 'orig', 
            runSynth(config, mod, tech, freq, maxopt)
