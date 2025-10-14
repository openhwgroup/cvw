#!/usr/bin/env python3
import argparse
import os
import subprocess

WALLY = os.environ.get("WALLY")
DEBUGTESTS = f"{WALLY}/tests/debug/build"

SPIKEARGS = " ".join([
    "--isa=rv64gc_zicsr",
    "--rbb-port=9824"
])

def non_empty_string(value):
    if not isinstance(value, str):
        raise argparse.ArgumentTypeError(f"Argument must be a string, got {type(value).__name__}")
    if len(value.strip()) == 0:
        raise argparse.ArgumentTypeError("Argument must be a non-empty string")
    return value

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--test", "-s", help="Assembly test.", type=non_empty_string)
    parser.add_argument("--tcl", "-t", help="TCL script to run parallel to assembly test.", type=non_empty_string)
    return parser.parse_args()

# def validate_args(args):
#     if (len(args.test) == 0):
        

def start_spike(test):
    return subprocess.Popen(["spike", SPIKEARGS, test])

def start_openocd(tclscript):
    return subprocess.Popen(["openocd", "-f", "openocd.cfg", "-c", tclscript])



def main(args):
    # spike_proc = start_spike(args.test)
    # openocd_proc = start_openocd(args.tcl)
    print(args)

if __name__ == "__main__":
    args = parse_args()
    main(args)
