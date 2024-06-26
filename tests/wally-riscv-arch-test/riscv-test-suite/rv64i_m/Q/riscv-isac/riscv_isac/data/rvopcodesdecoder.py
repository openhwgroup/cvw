import glob
from operator import itemgetter
from collections import defaultdict
import pprint
import os

from constants import *
import riscv_isac.plugins as plugins
from riscv_isac.log import logger

from riscv_isac.InstructionObject import instructionObject

# Closure to get argument value
def get_arg_val(arg: str):
    (msb, lsb) = arg_lut[arg]
    len = msb - lsb + 1
    mask = int(''.join('1' * (len)), 2) << lsb
    def mcode_in(mcode: int):
        val = (mask & mcode) >> lsb
        return f'{val:0{len}b}'
    return mcode_in

# Functs handler
def get_funct(pos_tuple: tuple, mcode: int):
    msb = pos_tuple[0]
    lsb = pos_tuple[1]
    mask = int(''.join('1' * (msb - lsb + 1)), 2) << lsb
    val = (mask & mcode) >> lsb

    return val

class disassembler():

    FIRST_TWO = 0x00000003
    OPCODE_MASK = 0x0000007f

    INST_LIST = []

    @plugins.decoderHookImpl
    def setup(self, arch: str):
        self.arch = arch

        # Create nested dictionary
        nested_dict = lambda: defaultdict(nested_dict)
        disassembler.INST_DICT = nested_dict()
        disassembler.create_inst_dict('*')

    def process_enc_line(line: str):

        functs = []
        args = []

        # get the name of instruction by splitting based on the first space
        [name, remaining] = line.split(' ', 1)

        # replace dots with underscores as dot doesn't work with C/Sverilog, etc
        name = name

        # remove leading whitespaces
        remaining = remaining.lstrip()

        # extract bit pattern assignments of the form hi..lo=val. fixed_ranges is a
        # regex expression present in constants.py. The extracted patterns are
        # captured as a list in args where each entry is a tuple (msb, lsb, value)

        opcode_parsed = fixed_ranges.findall(remaining)
        opcode_functs = []
        for func in opcode_parsed:
            opcode_functs.append([int(a, 0) for a in func])

        # Sort in ascending order of lsb
        opcode_functs = sorted(opcode_functs, key=itemgetter(1))
        for (msb, lsb, value) in opcode_functs:
            flen = msb - lsb + 1
            value = f"{value:0{flen}b}"
            value = int(value, 2)
            funct = (msb, lsb)

            functs.append((funct, value))

        # parse through the args
        args_list = fixed_ranges.sub(' ', remaining)
        args_list = single_fixed.sub(' ', args_list).split()
        for arg in args_list:
            args.append(arg)

        # do the same as above but for <lsb>=<val> pattern. single_fixed is a regex
        # expression present in constants.py
        for (lsb, value, drop) in single_fixed.findall(remaining):
            lsb = int(lsb, 0)
            value = int(value, 0)
            functs.append(((lsb, lsb), value))

        return (functs, (name, args))

    def create_inst_dict(file_filter):
        '''
        Gathers files and generates instruciton list from the filter given

        Input:
            file_filter:    (string) A file filter
        '''

        # Default riscv-opcodes directory
        opcodes_dir = os.path.join(os.path.dirname(__file__),"riscv_opcodes/")

        # file_names contains all files to be parsed in the riscv-opcodes directory
        file_names = glob.glob(f'{opcodes_dir}/rv{file_filter}')
        file_names += glob.glob(f'{opcodes_dir}/unratified/rv{file_filter}')

        # first pass for standard/original instructions
        for f in file_names:
            with open(f) as fp:
                lines = (line.rstrip()
                        for line in fp)                             # All lines including the blank ones
                lines = list(line for line in lines if line)        # Non-blank lines
                lines = list(
                    line for line in lines
                    if not line.startswith("#"))                    # Remove comment lines

            # go through each line of the file
            for line in lines:

                # ignore all lines starting with $import and $pseudo
                if '$import' in line or '$pseudo' in line:
                    continue

                (functs, (name, args)) = disassembler.process_enc_line(line)
                args.append(os.path.basename(f))

                # [  [(funct, val)], name, [args]  ]
                disassembler.INST_LIST.append([functs, name, args])

        # second pass for pseudo-ops
        for f in file_names:
            with open(f) as fp:
                lines = (line.rstrip()
                        for line in fp)                             # All lines including the blank ones
                lines = list(line for line in lines if line)        # Non-blank lines
                lines = list(
                    line for line in lines
                    if not line.startswith("#"))                    # Remove comment lines

            # go through each line of the file
            for line in lines:
                # ignore all lines not starting with $pseudo
                if '$pseudo' not in line:
                    continue

                # use the regex pseudo_regex from constants.py to find the dependent
                # extension, dependent instruction, the pseudo_op in question and
                # its encoding
                (ext, orig_inst, pseudo_inst, line) = pseudo_regex.findall(line)[0]

                # call process_enc_line to get the data about the current
                # instruction
                (functs, (name, args)) = disassembler.process_enc_line(pseudo_inst + ' ' + line)
                args.append(os.path.basename(f))

                # [  [(funct, val)], name, [args]  ]
                disassembler.INST_LIST.append([functs, name, args])

        # third pass for imports
        for f in file_names:
            with open(f) as fp:
                lines = (line.rstrip()
                        for line in fp)  # All lines including the blank ones
                lines = list(line for line in lines if line)  # Non-blank lines
                lines = list(
                    line for line in lines
                    if not line.startswith("#"))  # remove comment lines

            for line in lines:
                # if the an instruction needs to be imported then go to the
                # respective file and pick the line that has the instruction.
                # The variable 'line' will now point to the new line from the
                # imported file

                # ignore all lines starting with $import and $pseudo
                if '$import' not in line :
                    continue

                (import_ext, reg_instr) = imported_regex.findall(line)[0]

                path = opcodes_dir + import_ext
                # Find the file where the dependent extension exist.
                if not os.path.exists(path):
                    ext1 = f'{opcodes_dir}unratified/{import_ext}'
                    if not os.path.exists(ext1):
                        raise SystemExit(1)
                    else:
                        ext = ext1
                else:
                    ext = path

                # Fetch the dependent instruction
                for oline in open(ext):
                    if not re.findall(f'^\s*{reg_instr}',oline):
                        continue
                    else:
                        break

                (functs, (name, args)) = disassembler.process_enc_line(oline)
                args.append(os.path.basename(f))

                # [  [(funct, val)], name, [args]  ]
                disassembler.INST_LIST.append([functs, name, args])

        if not disassembler.INST_LIST:
            logger.error("No instruction encodings found.")
            raise SystemExit

        # Insert all instructions to the root of the dictionary
        disassembler.INST_DICT['root'] = disassembler.INST_LIST

        # Generate dictionary
        disassembler.build_instr_dict(disassembler.INST_DICT)

    def build_instr_dict(inst_dict):
        '''
        This function recursively generates the dictionary based on
        highest occurrence of functs in a particular path
        '''

        # Get all instructions in the level
        val = inst_dict['root']

        # Gather all functs
        funct_list = [item[0] for item in val]
        funct_occ = [funct[0] for ins in funct_list for funct in ins]

        # Path recoder
        funct_path = set()
        # Check if there are functions remaining
        while funct_occ:
            if (1, 0) in funct_occ:
                max_funct = (1, 0)
            else:
                max_funct = max(set(funct_occ),key=funct_occ.count)

            funct_occ = list(filter(lambda a: a != max_funct, funct_occ))

            i = 0
            # For each instruciton...
            while i < len(val):
                # For each funct of each instruction...
                for funct in val[i][0]:
                    if funct[0] == max_funct:
                        # Max funct found!

                        # Push into path recorder
                        funct_path.add(funct)

                        # Push funct and its value into the dict
                        temp_dict = inst_dict[funct[0]][funct[1]]

                        # Create empty list in the path
                        if not temp_dict:
                            inst_dict[funct[0]][funct[1]]['root'] = []

                        # Delete appended funct
                        temp = val[i]
                        temp[0].remove(funct)

                        if temp[0]:
                            # Add to the path
                            inst_dict[funct[0]][funct[1]]['root'].append(temp)

                            # Remove the copied instruction from previous list
                            inst_dict['root'].remove(val[i])
                        else:
                            # Append name and args
                            temp_dict[temp[1]] = temp[2]
                        i = i - 1
                i = i + 1
        else:
            # Remove previous root
            del inst_dict['root']

            for funct in funct_path:

                new_path = inst_dict[funct[0]][funct[1]]
                a = disassembler.build_instr_dict(new_path)
                if a == None:
                    continue
                else:
                    return a
            return

    def get_instr(func_dict, mcode: int):
        '''
        Recursively extracts the instruction from the dictionary
        '''
        global instr
        # Get list of functions
        keys = func_dict.keys()
        num_keys = len(keys)
        for key in keys:
            if type(key) == str and num_keys == 1:
                return (key, func_dict[key])
            elif type(key) == tuple:
                val = get_funct(key, mcode)
            else:                                       # There must be pseudo-ops
                instr = (key, func_dict[key])
                continue
            temp_func_dict = func_dict[key][val]
            if temp_func_dict.keys():
                a = disassembler.get_instr(temp_func_dict, mcode)
                if a == None:
                    continue
                else:
                    return a
            else:
                continue

    @plugins.decoderHookImpl
    def decode(self, instrObj_temp):
        '''
        Take an instruction object with just machine code and fill
        the instruction name and argument fields

        Input:
            temp_instrobj:  (instructionObject)
        Returns:
            (instructionObject) : Instruction object with names and arguments filled
            None                : When the dissassembler fails to decode the machine code
        '''
        global instr
        instr = None

        temp_instrobj = instrObj_temp
        mcode = temp_instrobj.instr
        name_args = disassembler.get_instr(disassembler.INST_DICT, mcode)
        if not name_args:
            name_args = instr

        # Fill out the partially filled instructionObject
        if name_args:
            instr_name = name_args[0]

            # Fill instruction name
            temp_instrobj.instr_name = instr_name
            # Fill arguments
            args = name_args[1]
            imm = ''
            # Get extension
            file_name = args[-1]
            # If instruction from P extension
            if file_name in ['rv_p', 'rv32_p', 'rv64_p']:
                temp_instrobj.is_rvp = True
            # Register type assignment
            reg_type = 'x'
            if file_name in ['rv_f', 'rv64_f', 'rv_d','rv64_d']:
                reg_type = 'f'
            for arg in args[:-1]:
                if 'rd' in arg:
                    treg = reg_type
                    if any([instr_name.startswith(x) for x in [
                            'fcvt.w','fcvt.l','fmv.s','fmv.d','flt','feq','fle','fclass']]):
                        treg = 'x'
                    temp_instrobj.rd = (int(get_arg_val(arg)(mcode), 2), treg)
                if 'rs1' in arg:
                    treg = reg_type
                    if any([instr_name.startswith(x) for x in [
                            'fsw','fsd','fcvt.s','fcvt.d','fmv.w','fmv.l']]):
                        treg = 'x'
                    temp_instrobj.rs1 = (int(get_arg_val(arg)(mcode), 2), treg)
                if 'rs2' in arg:
                    treg = reg_type
                    temp_instrobj.rs2 = (int(get_arg_val(arg)(mcode), 2), treg)
                if 'rs3' in arg:
                    treg = reg_type
                    temp_instrobj.rs3 = (int(get_arg_val(arg)(mcode), 2), treg)
                if 'csr' in arg:
                    temp_instrobj.csr = int(get_arg_val(arg)(mcode), 2)
                if arg == 'shamt':
                    temp_instrobj.shamt = int(get_arg_val(arg)(mcode), 2)
                if arg == 'shamt':
                    temp_instrobj.shamt = int(get_arg_val(arg)(mcode), 2)
                if arg == 'shamtw':
                    temp_instrobj.shamt = int(get_arg_val(arg)(mcode), 2)
                if arg == 'shamtw4':
                    temp_instrobj.shamt = int(get_arg_val(arg)(mcode), 2)
                if arg == 'succ':
                    temp_instrobj.succ = int(get_arg_val(arg)(mcode), 2)
                if arg == 'pred':
                    temp_instrobj.pred = int(get_arg_val(arg)(mcode), 2)
                if arg == 'rl':
                    temp_instrobj.rl = int(get_arg_val(arg)(mcode), 2)
                if arg == 'aq':
                    temp_instrobj.aq = int(get_arg_val(arg)(mcode), 2)
                if arg == 'rm':
                    temp_instrobj.rm = int(get_arg_val(arg)(mcode), 2)
                if arg == 'csr':
                    temp_instrobj.imm = int(get_arg_val(arg)(mcode), 2)
                if arg.find('imm') != -1:
                    if arg in ['imm12', 'imm20', 'zimm', 'imm2', 'imm3', 'imm4', 'imm5']:
                        imm = get_arg_val(arg)(mcode)
                    # Reoder immediates
                    if arg == 'jimm20':
                        imm_temp = get_arg_val(arg)(mcode)
                        imm = imm_temp[0] + imm_temp[12:21] + imm_temp[11] + imm_temp[1:11] + '0'
                    if arg == 'imm12hi':
                        imm_temp = get_arg_val(arg)(mcode)
                        imm = imm_temp + imm
                    if arg == 'imm12lo':
                        imm_temp = get_arg_val(arg)(mcode)
                        imm = imm + imm_temp
                    if arg == 'bimm12hi':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm_temp[0] + imm[-1] + imm_temp[1:] + imm[0:4] + '0'
                        else:
                            imm = imm_temp + imm
                    if arg == 'bimm12lo':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm[0] + imm_temp[-1] + imm[1:] + imm_temp[0:4] + '0'
                        else:
                            imm = imm + imm_temp
                    if arg == 'c_uimm7hi':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm[-1] + imm_temp + imm[0] + '00'
                        else:
                            imm = imm_temp + imm
                    if arg == 'c_uimm7lo':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm_temp[-1] + imm + imm_temp[0] + '00'
                        else:
                            imm = imm + imm_temp

                    if arg == 'c_uimm8lo':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm_temp[-1] + imm + imm_temp[0] + '00'
                        else:
                            imm = imm + imm_temp
                    if arg == 'c_uimm8hi':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm[-1] + imm_temp + imm[0] + '00'
                        else:
                            imm = imm_temp + imm

                    if arg == 'c_uimm9lo':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm_temp[-1] + imm + imm_temp[0] + '00'
                        else:
                            imm = imm + imm_temp
                    elif arg == 'c_uimm9hi':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm[-1] + imm_temp + imm[0] + '00'
                        else:
                            imm = imm_temp + imm

                    elif arg == 'c_nzimm6lo':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm_temp[-1] + imm + imm_temp[0] + '00'
                        else:
                            imm = imm + imm_temp
                    elif arg == 'c_nzimm6hi':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm[-1] + imm_temp + imm[0] + '00'
                        else:
                            imm = imm_temp + imm

                    elif arg == 'c_imm6lo':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm_temp[-1] + imm + imm_temp[0] + '00'
                        else:
                            imm = imm + imm_temp
                    elif arg == 'c_imm6hi':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm[-1] + imm_temp + imm[0] + '00'
                        else:
                            imm = imm_temp + imm

                    elif arg == 'c_nzimm10hi':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm[-1] + imm_temp + imm[0] + '00'
                        else:
                            imm = imm_temp + imm
                    elif arg == 'c_nzimm10lo':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm_temp[-1] + imm + imm_temp[0] + '00'
                        else:
                            imm = imm + imm_temp

                    elif arg == 'c_nzimm18hi':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm[-1] + imm_temp + imm[0] + '00'
                        else:
                            imm = imm_temp + imm
                    elif arg == 'c_nzimm18lo':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm_temp[-1] + imm + imm_temp[0] + '00'
                        else:
                            imm = imm + imm_temp

                    elif arg == 'c_imm12':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm[-1] + imm_temp + imm[0] + '00'
                        else:
                            imm = imm_temp + imm

                    elif arg == 'c_bimm9lo':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm_temp[-1] + imm + imm_temp[0] + '00'
                        else:
                            imm = imm + imm_temp
                    elif arg == 'c_bimm9hi':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm[-1] + imm_temp + imm[0] + '00'
                        else:
                            imm = imm_temp + imm

                    elif arg == 'c_nzuimm5':
                        imm_temp = get_arg_val(arg)(mcode)
                        imm = imm_temp + imm

                    elif arg == 'c_nzuimm6lo':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm_temp[-1] + imm + imm_temp[0] + '00'
                        else:
                            imm = imm + imm_temp


                    elif arg == 'c_nzuimm6hi':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm[-1] + imm_temp + imm[0] + '00'
                        else:
                            imm = imm_temp + imm

                    elif arg == 'c_uimm8splo':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm_temp[-1] + imm + imm_temp[0] + '00'
                        else:
                            imm = imm + imm_temp

                    elif arg == 'c_uimm8sphi':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm[-1] + imm_temp + imm[0] + '00'
                        else:
                            imm = imm_temp + imm

                    elif arg == 'c_uimm8sp_s':
                        imm_temp = get_arg_val(arg)(mcode)
                        imm = imm[-1] + imm_temp + imm[0] + '00'

                    elif arg == 'c_uimm10splo':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm_temp[-1] + imm + imm_temp[0] + '00'
                        else:
                            imm = imm + imm_temp

                    elif arg == 'c_uimm10sphi':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm[-1] + imm_temp + imm[0] + '00'
                        else:
                            imm = imm_temp + imm

                    elif arg == 'c_uimm9splo':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm_temp[-1] + imm + imm_temp[0] + '00'
                        else:
                            imm = imm + imm_temp

                    elif arg == 'c_uimm9sphi':
                        imm_temp = get_arg_val(arg)(mcode)
                        if imm:
                            imm = imm[-1] + imm_temp + imm[0] + '00'
                        else:
                            imm = imm_temp + imm

                    elif arg == 'c_uimm10sp_s':
                        imm_temp = get_arg_val(arg)(mcode)
                        imm = imm_temp + imm

                    elif arg == 'c_uimm9sp_s':
                        imm_temp = get_arg_val(arg)(mcode)
                        imm = imm_temp + imm

                    elif arg == 'c_nzuimm10':
                        imm_temp = get_arg_val(arg)(mcode)
                        imm = imm_temp + imm

            if imm:
                numbits = len(imm)
                temp_instrobj.imm = disassembler.twos_comp(int(imm, 2), numbits)
            return temp_instrobj
        else:
            return None

    # Utility functions
    def twos_comp(val, bits):
        '''
        Get the two_complement value
        '''
        if (val & (1 << (bits - 1))) != 0:
            val = val - (1 << bits)
        return val

    def default_to_regular(d):
        '''
        Utility function to convert nested defaultdict to regular dict
        '''
        if isinstance(d, defaultdict):
            d = {k: disassembler.default_to_regular(v) for k, v in d.items()}
        return d

    def print_instr_dict():
        '''
        Print out the dictionary map to a file
        '''
        printer = pprint.PrettyPrinter(indent=1, width=800, depth=None, stream=None,
                 compact=False, sort_dicts=False)

        s = printer.pformat(disassembler.default_to_regular(disassembler.INST_DICT))
        f = open('dict_tree.txt', 'w+')
        f.write(s)
        f.close()
