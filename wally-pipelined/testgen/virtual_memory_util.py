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


pgdir = []

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

      self.VPN_BITS = 20
      self.VPN_SEGMENT_BITS = 10

      self.PPN_BITS = 22

      self.LEVELS = 2
    elif (xlen == 64):
      self.PTESIZE = 8

      self.VPN_BITS = 27
      self.VPN_SEGMENT_BITS = 9

      self.PPN_BITS = 44

      self.LEVELS = 3
    else:
      raise ValueError('Only rv32 and rv64 are allowed.')

    self.PGSIZE = 2**12
    self.NPTENTRIES = self.PGSIZE // self.PTESIZE
    self.PTE_BITS = 8 * self.PTESIZE
    self.OFFSET_BITS = 12
    self.FLAG_BITS = 8

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
  Represents a single level of the page table, with  
  """
  def __init__(self, name, arch):
    self.table = {}
    self.name = name
    self.arch = arch

  def add_entry(self, vpn_segment, ppn_segment, flags, linked_table = None):
    if not (0 <= vpn_segment < 2**self.arch.VPN_SEGMENT_BITS):
      raise ValueError("Invalid virtual page segment number")
    self.table[vpn_segment] = (PageTableEntry(ppn_segment, flags, self.arch), linked_table)

  def add_mapping(self, va, pa, flags):
    if not (0 <= va < 2**self.arch.VPN_BITS):
      raise ValueError("Invalid virtual page number")
    for level in range(self.arch.LEVELS - 1, -1, -1):
      

    

  def assembly(self):
    entries = list(sorted(self.table.items(), key=lambda item: item[0]))
    current_index = 0
    asm = f".balign {self.arch.PGSIZE}\n{self.name}:\n"
    for entry in entries:
      vpn_index, (pte, _) = entry
      if current_index < vpn_index:
        asm += f"  .fill {vpn_index - current_index}, {self.arch.PTESIZE}, 0\n"
      asm += f"  .4byte {str(pte)}\n"
      current_index = vpn_index + 1
    if current_index < self.arch.NPTENTRIES:
      asm += f"  .fill {self.arch.NPTENTRIES - current_index}, {self.arch.PTESIZE}, 0\n"
    return asm

##################################
# functions
##################################

