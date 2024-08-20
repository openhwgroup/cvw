import sys
import os
from riscv_isac.log import logger
import riscv_isac.utils as utils
import riscv_isac.coverage as cov
from elftools.elf.elffile import ELFFile

def isac(output_file,elf ,trace_file, window_size, cgf, parser_name, decoder_name, parser_path, decoder_path, detailed, test_labels,
        sig_labels, dump, cov_labels, xlen, flen, no_count, procs, logging=False):
    test_addr = []
    sig_addr = []
    if parser_path:
        sys.path.append(parser_path)
    if decoder_path:
        sys.path.append(decoder_path)
    sys.path.append(os.path.join(os.path.dirname(__file__), "plugins"))

    if elf is not None :
        test_name = elf.rsplit('.', 1)[0]
        if test_labels:
            for startlabel,endlabel in test_labels:
                start_address = utils.collect_label_address(elf, startlabel)
                end_address = utils.collect_label_address(elf, endlabel)
                logger.info('Start Test Label: ' + startlabel + ' @ ' +
                        str(hex(start_address)))
                logger.info('End Test Label  : ' + endlabel + ' @ ' +
                        str(hex(end_address)))
                test_addr.append((start_address,end_address))
        if sig_labels:
            for startlabel,endlabel in sig_labels:
                start_address = utils.collect_label_address(elf, startlabel)
                end_address = utils.collect_label_address(elf, endlabel)
                logger.info('Start Signature Label: ' + startlabel + ' @ ' +
                        str(hex(start_address)))
                logger.info('End Signature Label  : ' + endlabel + ' @ ' +
                        str(hex(end_address)))
                sig_addr.append((start_address,end_address))
    else:
        test_name = trace_file.rsplit(',',1)[0]
    rpt = cov.compute(trace_file, test_name, cgf, parser_name, decoder_name, detailed, xlen, flen, test_addr, dump, cov_labels, sig_addr, window_size, no_count, procs)
    if output_file is not None and logging:
        logger.info('Coverage Report:')
        logger.info('\n\n' + rpt)
    else:
        rpt_file = open(output_file,'w')
        utils.dump_yaml(rpt, rpt_file)
        rpt_file.close()
        logger.info('Report File Generated : ' + str(output_file))
