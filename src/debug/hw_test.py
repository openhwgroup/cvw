import random
import time

from hw_interface import *


random_stimulus = False

def main():
    registers = dict.fromkeys(register_translations.keys(),[])
    reg_addrs = list(registers.keys())

    init()
    reset_dm()
    reset_hart()
    
    time.sleep(70) # wait for OpenSBI

    halt()
    status()

    # dump data in all registers
    for r in reg_addrs:
        try:
            data = read_data(r)
            registers[r] = data
            print(f"{r}: {data}")
        except Exception as e:
            if e.args[0] == "exception":  # Invalid register (not implemented)
                del registers[r]
                clear_abstrcmd_err()
            else:
                raise e
    input("Compare values to ILA, press any key to continue")

    # Write random data to all registers
    reg_addrs = list(registers.keys())
    if random_stimulus:
        random.shuffle(reg_addrs)
    test_reg_data = {}
    for r in reg_addrs:
        test_data = random_hex(r)
        try:
            write_data(r, test_data)
            test_reg_data[r] = test_data
            print(f"Writing {test_data} to {r}")
        except Exception as e:
            if e.args[0] == "not supported":  # Register is read only
                del registers[r]
                clear_abstrcmd_err()
            else:
                raise e
    
    check_errors()

    # GPR X0 is always 0
    test_reg_data["X0"] = "0x" + "0"*(XLEN//4)

    # Confirm data was written correctly
    reg_addrs = list(registers.keys())
    if random_stimulus:
        random.shuffle(reg_addrs)
    for r in reg_addrs:
        try:
            rdata = read_data(r)
        except Exception as e:
            raise e
        if rdata != test_reg_data[r]:
            raise Exception(f"Register {r} read did not return correct data: {rdata} != {test_reg_data[r]}")
        else:
            print(f"Read {rdata} from {r}")

    # Return all registers to original state
    reg_addrs = list(registers.keys())
    for r in reg_addrs:
        print(f"Writing {registers[r]} to {r}")
        try:
            write_data(r, registers[r])
        except Exception as e:
            raise e

    # Confirm data was written correctly
    for r in reg_addrs:
        try:
            rdata = read_data(r)
        except Exception as e:
            raise e
        if rdata != registers[r]:
            raise Exception(f"Register {r} read did not return correct data: {rdata} != {registers[r]}")
    print("All writes successful")

    resume()
    status()


def random_hex(reg_name):
    if reg_name in nonstandard_register_lengths:
        size = nonstandard_register_lengths[reg_name]
        pad = (XLEN-size) // 4
    else:
        size = XLEN
        pad = 0
    
    if random_stimulus:
        return f"0x{"0"*pad}{random.getrandbits(size):x}"
    else:
        data = 0xa5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5
        return f"0x{"0"*pad}{(data & (2**size-1)):x}"


main()