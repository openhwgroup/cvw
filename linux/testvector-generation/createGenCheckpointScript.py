#! /usr/bin/python3
import sys

if len(sys.argv) != 8:
    sys.exit("""Error createGenCheckpointScript.py expects 7 args:
    <TCP port number>
    <path to vmlinux>
    <checkpoint instruction count>
    <path to GDB checkpoint state dump>
    <path to GDB ram dump>
    <checkpoint pc address>
    <number of times pc has already been hit before checkpoint>""")

tcpPort=sys.argv[1]
vmlinux=sys.argv[2]
instrCount=sys.argv[3]
statePath=sys.argv[4]
ramPath=sys.argv[5]
checkPC=sys.argv[6]
checkPCoccurences=sys.argv[7]

GDBscript = f"""
# GDB config
set pagination off
set logging overwrite on
set logging redirect on
set confirm off

# Connect to QEMU session
target extended-remote :{tcpPort}

# QEMU Config
maintenance packet Qqemu.PhyMemMode:1

# Symbol file
file {vmlinux}

# Step over reset vector into actual code
stepi 100
# Proceed to checkpoint 
print "GDB proceeding to checkpoint at {instrCount} instrs, pc {checkPC}\\n"
b *0x{checkPC}
ignore 1 {checkPCoccurences}
c
print "Reached checkpoint at {instrCount} instrs\\n"

# Log all registers to a file
printf "GDB storing state to {statePath}\\n"
set logging file {statePath}
set logging on
info all-registers
set logging off

# Log main memory to a file
print "GDB storing RAM to {ramPath}\\n"
dump binary memory {ramPath} 0x80000000 0xffffffff

# Generate Trace Until End
maintenance packet Qqemu.Logging:1
# Do this by setting an impossible breakpoint
b *0x1000
del 1
c
"""
GDBscriptFile = open("genCheckpoint.gdb",'w')
GDBscriptFile.write(GDBscript)
GDBscriptFile.close()
