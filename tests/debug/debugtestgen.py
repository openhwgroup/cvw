#!/usr/bin/env python3
import argparse
import os
import subprocess
import time

WALLY = os.environ.get("WALLY")
DEBUGTESTS = f"{WALLY}/tests/debug/build"
ISA = "rv64gc_zicsr"
RBBPORT = "9824"

SPIKEARGS = [
    "spike",
    "--isa=rv64gcB_zicsr_zicntr",
    "--rbb-port=9824",
    "--dm-progsize=0",
    "--dm-no-hasel",
    "--dm-no-abstract-fpr",
    "--dm-no-halt-groups",
    "--dm-no-impebreak",
    "+signature-granularity=4"
]

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

def start_spike(test):
    spikeargs = SPIKEARGS
    spikeargs = spikeargs + [f"+signature={os.path.splitext(args.test)[0]}.signature.output", test]
    print(" ".join(spikeargs))
    return subprocess.Popen(spikeargs)

def start_openocd(tclscript):
    openocd_args = ["openocd", "-f", "openocd.cfg", "-c", f"source {tclscript}"]
    print(" ".join(openocd_args))
    return subprocess.Popen(openocd_args)

def main(args):
    start_spike(args.test)
    time.sleep(0.5)
    openocd_proc = start_openocd(args.tcl)
    openocd_proc.wait()
    print(os.path.splitext(args.test))

if __name__ == "__main__":
    args = parse_args()
    main(args)
