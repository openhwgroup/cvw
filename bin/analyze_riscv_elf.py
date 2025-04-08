#!/usr/bin/env python3

"""
james.stine@okstate.edu 8 April 2025

Purpose: Analyze a RISC-V ELF file and report which instructions are used,
         along with their frequency. The script disassembles the ELF using
         riscv64-unknown-elf-objdump, filters real instructions (excluding
         pseudo-ops and section headers), and displays a histogram of 
         instruction use.
"""

import subprocess
import sys
import re
from collections import Counter

def disassemble_elf(elf_path):
    try:
        result = subprocess.run(
            ["riscv64-unknown-elf-objdump", "-d", "-M", "no-aliases", elf_path],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"Error running objdump: {e.stderr}")
        sys.exit(1)

def extract_instructions(disassembly):
    instructions = []
    for line in disassembly.splitlines():
        # Match instruction lines only: address: machine-code instruction [operands...]
        match = re.match(r'^\s*[0-9a-f]+:\s+([0-9a-f]{8}|\s{8})\s+(\S+)', line)
        if match:
            instr = match.group(2)
            instructions.append(instr)
    return instructions

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 analyze_riscv_elf.py <file.elf>")
        sys.exit(1)

    elf_path = sys.argv[1]
    disassembly = disassemble_elf(elf_path)
    instructions = extract_instructions(disassembly)
    counter = Counter(instructions)

    print(f"\nInstruction usage in {elf_path}:\n")
    if not counter:
        print("No instructions found (did you use the correct target ELF file?)")
    else:
        for instr, count in counter.most_common():
            count_str = f"{count:,}"  # Add comma as thousands separator
            print(f"{instr:<10} {count_str}")

if __name__ == "__main__":
    main()

