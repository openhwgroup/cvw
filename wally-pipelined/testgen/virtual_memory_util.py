#!/usr/bin/python3
##################################
# virtual_memory_util.py
#
# Jessica Torrey <jtorrey@hmc.edu>  01 March 2021
# Thomas Fleming <tfleming@hmc.edu> 01 March 2021
#
# Utility functions for simulating and testing virtual memory on RISC-V.
##################################

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

##################################
# classes
##################################
class Architecture:
  def __init__(self, xlen):
    if (xlen == 32):
      self.PTESIZE = 4
      self.PTE_BITS = 32

      self.VPN_BITS = 20
      self.VPN_SEGMENT_BITS = 10

      self.PPN_BITS = 22

      self.LEVELS = 2
    elif (xlen == 64):
      self.PTESIZE = 8
      self.PTE_BITS = 54

      self.VPN_BITS = 27
      self.VPN_SEGMENT_BITS = 9

      self.PPN_BITS = 44

      self.LEVELS = 3
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

INITIAL_PPN = 0x80002
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
rv32 = Architecture(32)
rv64 = Architecture(64)

if __name__ == "__main__":
  arch = rv32
  pgdir = PageTable("page_directory", next_ppn(), arch)

  # Directly map the first 20 pages of RAM
  for page in range(20):
    vaddr = 0x80000000 + (arch.PGSIZE * page)
    paddr = 0x80000000 + (arch.PGSIZE * page)
    pgdir.add_mapping(vaddr, paddr, PTE_D | PTE_A | PTE_R | PTE_W | PTE_U | PTE_X | PTE_V)
  """
  supervisor_pgdir = PageTable("sdir", next_ppn(), rv64)
  supervisor_pgdir.add_mapping(0x80000000, 0x80000000, PTE_R | PTE_W | PTE_X)
  supervisor_pgdir.add_mapping(0x80000001, 0x80000001, PTE_R | PTE_W | PTE_X)
  supervisor_pgdir.add_mapping(0x80001000, 0x80000000, PTE_R | PTE_W | PTE_X)
  supervisor_pgdir.add_mapping(0xffff0000, 0x80000000, PTE_R | PTE_W | PTE_X)
  """

  print_pages()
