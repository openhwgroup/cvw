#!/usr/bin/python3
##################################
# virtual_memory_util.py
#
# Jessica Torrey <jtorrey@hmc.edu>  01 March 2021
# Thomas Fleming <tfleming@hmc.edu> 01 March 2021
#
# Modified kmacsaigoren@hmc.edu 2 June 2021
#             file now reflects actual use to generate assembly code pagetable.
#             file now also includes small guide on how it can be used.
#
# Utility for generating the pagetable for any test assembly code where virtual memory is needed.
##################################

######################################################
""" HOW TO USE THIS FILE
    
This is all assuming you are writing code very similar to the WALLY-VIRTUALMEMORY tests and would like your own virtual memory map.
This guide is also stored in the WALLY-VIRTUALMEMORY.S file as well.

Begin by copying an existing page directory over to your test and running make (it'll be wrong, but we'll fix it in a second).
  Make may hang or give you an error because the reference outputs may be wrong, but all we're trying to do is get an elf file.
Simulate the test code on your favorite riscv processor simulator with a debugger that will show you internal state/register values.
  I used OVPsimPlus with the command 'riscvOVPsimPlus.exe --variant <Variant name, ex: RV64I> --program <path to elf file> --gdbconsole'
Run through the simulation until it has written to satp and read the bottom 60 bits of it. 
  Assuming you're a test with the same setup code, this should be the value of the base ppn.

Near the top of the python file you're reading right now, edit the value of 'INITIAL_PPN' to be the base PPN you just found in hex.

Now find the mappings at the very bottom of the python file.
Each of these loops is adding a mapping from each virtual page in the loop to a physical page somewhere in RAM. 

add or remove mappings as you see fit. the first loop maps VPNs of 0x80000 to 0x80014 onto PPNs of 0x80000 to 0x80014
  you can map single pages or ranges of pages. you can also map multiple VPNs onto the same PPN.
  Make sure NOT to include the final VPN that causes the page fault in your test or your program will hang on the j loop instruction (unless you change the end condition).

double check that you're using the right architecture/svmode in the 'arch' variable

then run this python file and paste its output at the bottom of your assembly code. Be sure not to delete the signature fills.

email kmacsaigoren@hmc.edu if you have any questions and he might be able to remember the answers.

*** Currently doesn't work: mapping something with nonzeros in the VPN[3] feild onto any physical aderss. 
    It'll produce a page table, but writing to those virtual adresses will not correspond to the correctly mapped physical adresses.

    additionally, the expected behaviour doesn't really work when we try to map to a ram afress that starts with something larger than 000000008
    This could be ebcause of the 32 bit adress space for physical memory.

    remember that these things are broken with this program that generates page tables for test code. it does not say whether the test or module
    itself works or not.
*/

"""
######################################################

##################################
# libraries
##################################
from datetime import datetime
from random import randint, seed, getrandbits
from textwrap import dedent

##################################
# global structures
##################################
PTE_D = 1 << 7
PTE_A = 1 << 6
PTE_G = 1 << 5
PTE_U = 1 << 4
PTE_X = 1 << 3
PTE_W = 1 << 2
PTE_R = 1 << 1
PTE_V = 1 << 0

PTE_PTR_MASK = ~(PTE_W | PTE_R | PTE_X)

pgdir = []

pages = {}


testcase_num = 0
signature_len = 2000
signature = [0xff for _ in range(signature_len)]

# Base PPN, comes after 2 pages of test code and 2 pages of filler signature output space.
# depending on your test however, this value may be different. You can use OVPsimPlus or QEMU with your testcode to find it. 
INITIAL_PPN = 0x80005


##################################
# classes
##################################
class Architecture:
  def __init__(self, xlen, svMode):
    if (xlen == 32):
      self.PTESIZE = 4 # bytes
      self.PTE_BITS = 32

      self.VPN_BITS = 20
      self.VPN_SEGMENT_BITS = 10

      self.PPN_BITS = 22

      self.LEVELS = 2
    elif (xlen == 64):
      if (svMode == 39): 
        self.PTESIZE = 8
        self.PTE_BITS = 54

        self.VPN_BITS = 27
        self.VPN_SEGMENT_BITS = 9

        self.PPN_BITS = 44

        self.LEVELS = 3
      elif (svMode == 48):
        self.PTESIZE = 8
        self.PTE_BITS = 54

        self.VPN_BITS = 36
        self.VPN_SEGMENT_BITS = 9

        self.PPN_BITS = 44

        self.LEVELS = 4
      else:
        raise ValueError('Only Sv39 and Sv48 are implemented')
    else:
      raise ValueError('Only rv32 and rv64 are allowed.')

    self.PGSIZE = 2**12
    self.NPTENTRIES = self.PGSIZE // self.PTESIZE
    self.OFFSET_BITS = 12
    self.FLAG_BITS = 8
    self.VA_BITS = self.VPN_BITS + self.OFFSET_BITS

class PageTableEntry:
  def __init__(self, ppn, flags, arch):
    assert 0 <= ppn and ppn < 2**arch.PPN_BITS, "Invalid physical page number for PTE"
    assert 0 <= flags and flags < 2**arch.FLAG_BITS, "Invalid flags for PTE"
    self.ppn = ppn
    self.flags = flags
    self.arch = arch

  def entry(self):
    return (self.ppn << (self.arch.PTE_BITS - self.arch.PPN_BITS)) | self.flags

  def __str__(self):
    return "0x{0:0{1}x}".format(self.entry(), self.arch.PTESIZE*2)

  def __repr__(self):
    return f"<ppn: {hex(self.ppn)}, flags: {self.flags:08b}>"

class PageTable:
  """
  Represents a single level of the page table, located at some physical page
  number `ppn` with symbol `name`, using a specified architecture `arch`.
  """
  def __init__(self, name, ppn, arch):
    self.table = {}
    self.name = name
    self.ppn = ppn
    self.arch = arch

    self.children = 0

    pages[ppn] = self

  def add_entry(self, vpn_segment, ppn, flags):
    if not (0 <= vpn_segment < 2**self.arch.VPN_SEGMENT_BITS):
      raise ValueError("Invalid virtual page segment number")
    self.table[vpn_segment] = PageTableEntry(ppn, flags, self.arch)

  def add_mapping(self, va, pa, flags):
    """
    Maps a virtual address `va` to a physical address `pa` with given `flags`,
    creating missing page table levels as needed.
    """
    if not (0 <= va < 2**self.arch.VA_BITS):
      raise ValueError("Invalid virtual page number")

    vpn = virtual_to_vpn(va, self.arch)
    ppn = pa >> self.arch.OFFSET_BITS
    current_level = self

    pathname = self.name

    for level in range(self.arch.LEVELS - 1, -1, -1):
      if level == 0:
        current_level.add_entry(vpn[level], ppn, flags)
      elif vpn[level] in current_level.table:
        current_level = pages[current_level.table[vpn[level]].ppn]
        pathname += f"_{current_level.name}"
      else:
        next_level_ppn = next_ppn()
        current_level.add_entry(vpn[level], next_level_ppn, flags & PTE_PTR_MASK)
        pathname += f"_t{current_level.children}"
        current_level.children += 1
        pages[next_level_ppn] = PageTable(pathname, next_level_ppn, self.arch)
        current_level = pages[next_level_ppn]

  def assembly(self):
    # Sort the page table
    entries = list(sorted(self.table.items(), key=lambda item: item[0]))
    current_index = 0

    # Align the table
    asm = f".balign {self.arch.PGSIZE}\n{self.name}:\n"
    for entry in entries:
      vpn_index, pte = entry
      if current_index < vpn_index:
        asm += f"  .fill {vpn_index - current_index}, {self.arch.PTESIZE}, 0\n"
      asm += f"  .{self.arch.PTESIZE}byte {str(pte)}\n"
      current_index = vpn_index + 1
    if current_index < self.arch.NPTENTRIES:
      asm += f"  .fill {self.arch.NPTENTRIES - current_index}, {self.arch.PTESIZE}, 0\n"
    return asm
  
  def __str__(self):
    return self.assembly()

  def __repr__(self):
    return f"<table: {self.table}>"


##################################
# functions
##################################

def virtual_to_vpn(vaddr, arch):
  if not (0 <= vaddr < 2**arch.VA_BITS):
    raise ValueError("Invalid physical address")

  page_number = [0 for _ in range(arch.LEVELS)]

  vaddr = vaddr >> arch.OFFSET_BITS
  mask = 2**arch.VPN_SEGMENT_BITS - 1
  for level in range(arch.LEVELS):
    page_number[level] = vaddr & mask
    vaddr = vaddr >> arch.VPN_SEGMENT_BITS

  return page_number

next_free_ppn = INITIAL_PPN
def next_ppn():
  global next_free_ppn
  ppn = next_free_ppn
  next_free_ppn += 1
  return ppn

def print_pages():
  for page in pages:
    print(pages[page])

##################################
# helper variables
##################################
sv32 = Architecture(32, 32)
sv39 = Architecture(64, 39)
sv48 = Architecture(64, 48)

if __name__ == "__main__":
  arch = sv39
  pgdir = PageTable("page_directory", next_ppn(), arch)

  # Directly map the first 20 pages of RAM
  for page in range(20):
    vaddr = 0x80000000 + (arch.PGSIZE * page)
    paddr = 0x80000000 + (arch.PGSIZE * page)
    pgdir.add_mapping(vaddr, paddr, PTE_D | PTE_A | PTE_R | PTE_W | PTE_U | PTE_X | PTE_V)

  # Map Vpn of of the offset below and the 20 pages after it mapped onto the same 20 pages of ram.
  # the first two of these are also the location of the output for each test.
  for page in range(40):
    vaddr = 0x00000000 + (arch.PGSIZE * page)
    paddr = 0x80000000 + (arch.PGSIZE * page)
    if page >= 20:
      pgdir.add_mapping(vaddr, paddr, PTE_D | PTE_A | PTE_R | PTE_W | PTE_U | PTE_X | 0) # gives me an invalid mapping where I can try to store/read to force a page fault.
    else:
      pgdir.add_mapping(vaddr, paddr, PTE_D | PTE_A | PTE_R | PTE_W | PTE_U | PTE_X | PTE_V)


  """
  supervisor_pgdir = PageTable("sdir", next_ppn(), rv64)
  supervisor_pgdir.add_mapping(0x80000000, 0x80000000, PTE_R | PTE_W | PTE_X)
  supervisor_pgdir.add_mapping(0x80000001, 0x80000001, PTE_R | PTE_W | PTE_X)
  supervisor_pgdir.add_mapping(0x80001000, 0x80000000, PTE_R | PTE_W | PTE_X)
  supervisor_pgdir.add_mapping(0xffff0000, 0x80000000, PTE_R | PTE_W | PTE_X)
  """

  print_pages()
