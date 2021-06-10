#! /usr/bin/python3

instrs = 0
def readBlock(f, start, end):
  l = f.readline()
  if not l:
    quit()
  while not (l.startswith(start) and 'in ' not in l):
    l = f.readline()
    if not l:
      quit()
  ret = l
  while not l.startswith(end):
    l = f.readline()
    if not l:
      quit()
    ret += l
  return ret.split('\n'), f.readline()

with open('gdbcombined.txt', 'w') as out:
  with open('/mnt/scratch/riscv_gp/riscv_gp.txt', 'r') as gp:
    with open('/mnt/scratch/riscv_sp1/riscv_sp1.txt', 'r') as sp1:
      with open('/mnt/scratch/riscv_sp2/riscv_sp2.txt', 'r') as sp2:
        with open('/mnt/scratch/riscv_sp3/riscv_sp3.txt', 'r') as sp3:
          with open('/mnt/scratch/riscv_decodepc_threads/riscv_decodepc.txt.disassembly', 'r') as inst:
            inst.readline()
            while(True):
              instrs += 1
              g, i1 = readBlock(gp, 'ra', 't6')
              p1, i2 = readBlock(sp1, 'mie', 'scounteren')
              p2, i3 = readBlock(sp2, '0x', 'mideleg')
              p3, i4 = readBlock(sp3, 'mcause', 'stvec')
              instr = inst.readline()
              if not instr:
                quit()
              while '...' in instr:
                instr = inst.readline()
                if not instr:
                  quit()
              if i1 != i2 or i2 != i3 or i3 != i4 or int(p2[0].split()[0].split(':')[0], 16) != int(instr.split()[0].split(':')[0], 16):
                print("error: PC was not the same")
                print("instruction {}".format(instrs))
                print(i1)
                print(i2)
                print(i3)
                print(i4)
                print(p2[0])
                print(instr)
                quit()
              if "unimp" in instr:
                instrs -= 1
                continue
              out.write('=> {}'.format(instr.split(':')[2][1:].replace(' ', ':\t', 1)))
              out.write(p2[0] + '\n')
              out.write("zero           0x0      0\n")
              out.write("\n".join(g))
              pc = p2[0].split()[0]
              if pc.endswith(':'):
                pc = pc[:-1]
              out.write("pc             {}   {}\n".format(pc, pc))
              out.write("\n".join(p1))
              out.write("\n".join(p3))
              out.write("\n".join(p2[2:]))
              out.write("-----\n")
              if instrs % 10000 == 0:
                print(instrs)
              #if instrs >= 1000010:
              #  quit()
