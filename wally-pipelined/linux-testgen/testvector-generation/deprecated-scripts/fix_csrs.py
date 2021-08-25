#! /usr/bin/python3
import sys, fileinput

sys.stderr.write("reminder: fix_csrs.py is nothing but hardcoded hackery to combat QEMU's faulty printing")

csrs = ['fcsr','mcause','mcounteren','medeleg','mepc','mhartid','mideleg','mie','mip','misa','mscratch','mstatus','mtval','mtvec','pmpaddr0','pmpcfg0','satp','scause','scounteren','sepc','sie','sscratch','sstatus','stval','stvec']

# just for now, since these CSRs aren't yet ready to be checked in testbench-linux
list(map(csrs.remove, ['fcsr','mhartid','pmpcfg0','pmpaddr0','mip']))
output_path = sys.argv[1]+'/'
print(f'output dir: {output_path}')
count = 0
csr = ''
with open('{}parsedCSRs.txt'.format(output_path), 'w') as fixedCSRs:
    with open('{}/intermediate-outputs/unfixedParsedCSRs.txt'.format(output_path), 'r') as rawCSRs:
      for l in rawCSRs:
          fixedCSRs.write(l)
          count += 1
          if '---' in l:
              count = 0
          if (count%2 == 1): # every other line is CSR name
              csr = l
          else:
              if ('stval' in csr) and ('8020007e' in l):
                  print('Adding stvec vector')
                  fixedCSRs.write('stvec\n')
                  fixedCSRs.write('ffffffff800000b0\n')
          
