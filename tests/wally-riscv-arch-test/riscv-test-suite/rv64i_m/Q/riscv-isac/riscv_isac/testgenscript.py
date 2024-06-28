from riscv_isac.fpdatasetgen import *

import os
with open('ibm_b1_output.txt', 'r') as f: # .txt file to be generated from fpvcvpts.py
    coverpoints = f.readlines()
template_file = 'test_template.s' # path to sample template - should be replaced with riscv-arch-test template - adapt from a double precision template
os.makedirs('tests', exist_ok=True)

for idx, coverpoint in enumerate(coverpoints):
    fields = coverpoint.split('#')[0].split('and')
    fs1, fe1, fm1 = fields[0].split('==')[1].strip(), fields[1].split('==')[1].strip(), fields[2].split('==')[1].strip()
    fs2, fe2, fm2 = fields[3].split('==')[1].strip(), fields[4].split('==')[1].strip(), fields[5].split('==')[1].strip()
    rs1_val, rs2_val = coverpoint.split('#')[1].strip().split('and')


    with open(f'tests/test_{idx}.s', 'w') as f:
        with open(template_file, 'r') as template:
            for line in template:
                line = line.replace('<TEST_CASE_NAME>', f'Test Case {idx}')
                line = line.replace('<COVERPOINT>', coverpoint.strip())
                line = line.replace('<OP1_VALUE>', rs1_val.split('==')[1].strip("()"))
                line = line.replace('<OP2_VALUE>', rs2_val.split('==')[1].strip("()")) #***computational only; modification required for load/store
                f.write(line)

print(f'Generated {len(coverpoints)} test files in the "tests" directory.')