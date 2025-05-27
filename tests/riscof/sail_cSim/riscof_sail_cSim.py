import logging
import os
import re
import shutil

import riscof.utils as utils
from riscof.pluginTemplate import pluginTemplate

logger = logging.getLogger()

class sail_cSim(pluginTemplate):
    __model__ = "sail_c_simulator"
    __version__ = "0.5.0"

    def __init__(self, *args, **kwargs):
        sclass = super().__init__(*args, **kwargs)

        config = kwargs.get('config')
        if config is None:
            logger.error("Config node for sail_cSim missing.")
            raise SystemExit(1)
        self.num_jobs = str(config['jobs'] if 'jobs' in config else 1)
        self.pluginpath = os.path.abspath(config['pluginpath'])
        self.sail_exe = { '32' : os.path.join(config['PATH'] if 'PATH' in config else "","riscv_sim_rv32d"),
                '64' : os.path.join(config['PATH'] if 'PATH' in config else "","riscv_sim_rv64d")}
        self.isa_spec = os.path.abspath(config['ispec']) if 'ispec' in config else ''
        self.platform_spec = os.path.abspath(config['pspec']) if 'ispec' in config else ''
        # self.coverage_file = os.path.abspath(config['coverage']) if 'coverage' in config else ''
        self.make = config['make'] if 'make' in config else 'make'
        logger.debug("SAIL CSim plugin initialised using the following configuration.")
        for entry in config:
            logger.debug(entry+' : '+config[entry])
        return sclass

    def initialise(self, suite, work_dir, archtest_env):
        self.suite = suite
        self.work_dir = work_dir
        self.objdump_cmd = 'riscv64-unknown-elf-objdump -D {0} > {2};'
        self.compile_cmd = 'riscv64-unknown-elf-gcc -march={0} \
         -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles\
         -T '+self.pluginpath+'/env/link.ld\
         -I '+self.pluginpath+'/env/\
         -I ' + archtest_env

    def build(self, isa_yaml, platform_yaml):
        ispec = utils.load_yaml(isa_yaml)['hart0']
        self.xlen = ('64' if 64 in ispec['supported_xlen'] else '32')
        self.isa = 'rv' + self.xlen
        self.compile_cmd = self.compile_cmd+' -mabi='+('lp64 ' if 64 in ispec['supported_xlen'] else ('ilp32e ' if "E" in ispec["ISA"] else 'ilp32 '))
        if "I" in ispec["ISA"]:
            self.isa += 'i'
        if "E" in ispec["ISA"]:
            self.isa += 'e'
        if "M" in ispec["ISA"]:
            self.isa += 'm'
        if "A" in ispec["ISA"]:
            self.isa += 'a'
        if "C" in ispec["ISA"]:
            self.isa += 'c'
        if "F" in ispec["ISA"]:
            self.isa += 'f'
        if "D" in ispec["ISA"]:
            self.isa += 'd'
        if "Q" in ispec["ISA"]:
            self.isa += 'q'
        if "V" in ispec["ISA"]:
            self.isa += 'v'
        objdump = "riscv64-unknown-elf-objdump"
        if shutil.which(objdump) is None:
            logger.error(objdump+": executable not found. Please check environment setup.")
            raise SystemExit(1)
        compiler = "riscv64-unknown-elf-gcc"
        if shutil.which(compiler) is None:
            logger.error(compiler+": executable not found. Please check environment setup.")
            raise SystemExit(1)
        if shutil.which(self.sail_exe[self.xlen]) is None:
            logger.error(self.sail_exe[self.xlen]+ ": executable not found. Please check environment setup.")
            raise SystemExit(1)
        if shutil.which(self.make) is None:
            logger.error(self.make+": executable not found. Please check environment setup.")
            raise SystemExit(1)


    def runTests(self, testList, cgf_file=None):
        if os.path.exists(self.work_dir+ "/Makefile." + self.name[:-1]):
            os.remove(self.work_dir+ "/Makefile." + self.name[:-1])
        make = utils.makeUtil(makefilePath=os.path.join(self.work_dir, "Makefile." + self.name[:-1]))
        make.makeCommand = self.make + ' -j' + self.num_jobs

        # TODO: This bit is temporary until riscof properly copies over the coverage file
        self.coverage_file = f"{self.pluginpath}/../spike/coverage_rv{self.xlen}gc.svh"
        # Copy coverage file to wkdir
        cov_copy_command = f'cp {self.coverage_file} {self.work_dir}/coverage.svh;'
        os.system(cov_copy_command)

        for file in testList:
            testentry = testList[file]
            test = testentry['test_path']
            test_dir = testentry['work_dir']
            test_name = test.rsplit('/',1)[1][:-2]

            elf = 'ref.elf'

            execute = "@cd "+testentry['work_dir']+";"

            cmd = self.compile_cmd.format(testentry['isa'].lower(), self.xlen) + ' ' + test + ' -o ' + elf
            compile_cmd = cmd + ' -D' + " -D".join(testentry['macros'])
            execute+=compile_cmd+";"

            execute += self.objdump_cmd.format(elf, self.xlen, 'ref.elf.objdump')
            sig_file = os.path.join(test_dir, self.name[:-1] + ".signature")
            
            # Check if the tests can be run on SAIL
            if ('NO_SAIL=True' in testentry['macros']):
                # if the tests can't run on SAIL we copy the reference output to the src directory
                reference_output = re.sub("/src/","/references/", re.sub(".S",".reference_output", test))
                execute += f'cut -c-{8:g} {reference_output} > {sig_file}' #use cut to remove comments when copying
            else:
                execute += self.sail_exe[self.xlen] + f' --config {self.pluginpath}/rv{self.xlen}gc.json --trace=step --test-signature={sig_file} {elf} > {test_name}.log 2>&1;'

                # Coverage
                if (os.environ.get('COLLECT_COVERAGE') == "true"): # TODO: update this to take a proper flag from riscof, not use env vars
                    # Generate trace from sail log
                    cvw_arch_verif_dir = os.getenv('CVW_ARCH_VERIF') # TODO: update this to not depend on env var
                    trace_command = f'{cvw_arch_verif_dir}/bin/sail-parse.py {test_name}.log {test_name}.trace;'
                    execute += trace_command

                    # Generate ucdb coverage file
                    questa_do_file = f'{cvw_arch_verif_dir}/bin/cvw-arch-verif.do'
                    coverage_command = f'vsim -c -do "do {questa_do_file} {test_dir} {test_name} {cvw_arch_verif_dir}/fcov {self.work_dir}";'
                    execute += coverage_command

            make.add_target(execute)
#        make.execute_all(self.work_dir)
# DH 7/26/22 increase timeout so sim will finish on slow machines
# DH 5/17/23 increase timeout to 3600 seconds
        make.execute_all(self.work_dir, timeout = 3600)
