#!/usr/bin/env python3
# extract sqrt and float div testfloat vectors

# author: Alessandro Maiuolo
# contact: amaiuolo@g.hmc.edu
# date created: 3-29-2023

import os
wally = os.popen('echo $WALLY').read().strip()
# print(wally)

def ext_bits(my_string):
    target_len = 32 # we want 128 bits, div by 4 bc hex notation
    zeroes_to_add = target_len - len(my_string)
    return zeroes_to_add*"0" + my_string

# rounding mode dictionary
round_dict = {
    "rne":"0",
    "rnm":"4",
    "ru":"3",
    "rz":"1",
    "rd":"2",
    "dyn":"7"
}


print("creating testfloat div test vectors")

source_dir = "{}/tests/fp/vectors/".format(wally)
dest_dir = "{}/tests/fp/combined_IF_vectors/IF_vectors/".format(wally)
all_vectors = os.listdir(source_dir)

div_vectors = [v for v in all_vectors if "div" in v]

# iterate through all float div vectors
for vector in div_vectors:
    # use name to determine configs
    config_list = vector.split(".")[0].split("_")
    operation = "1" #float div
    rounding_mode = round_dict[str(config_list[2])]
    # use name to create our new tv
    dest_file = open(dest_dir + "cvw_" + vector, 'a')
    # open vector
    src_file = open(source_dir + vector,'r')
    # for each test in the vector
    for i in src_file.readlines():
        translation = "" # this stores the test that we are currently working on
        [input_1, input_2, answer, flags] = i.split("_") # separate inputs, answer, and flags
        # put it all together, strip nec for removing \n on the end of the flags
        translation = "{}_{}_{}_{}_{}_{}".format(operation, ext_bits(input_1), ext_bits(input_2), ext_bits(answer), flags.strip(), rounding_mode)
        dest_file.write(translation + "\n")
    dest_file.close()
    src_file.close()


print("creating testfloat sqrt test vectors")

sqrt_vectors = [v for v in all_vectors if "sqrt" in v]

# iterate through all float div vectors
for vector in sqrt_vectors:
    # use name to determine configs
    config_list = vector.split(".")[0].split("_")
    operation = "2" #sqrt
    rounding_mode = round_dict[str(config_list[2])]
    # use name to create our new tv
    dest_file = open(dest_dir + "cvw_" + vector, 'a')
    # open vector
    src_file = open(source_dir + vector,'r')
    # for each test in the vector
    for i in src_file.readlines():
        translation = "" # this stores the test that we are currently working on
        [input_1, answer, flags] = i.split("_") # separate inputs, answer, and flags
        # put it all together, strip nec for removing \n on the end of the flags
        translation = "{}_{}_{}_{}_{}_{}".format(operation, ext_bits(input_1), "X"*32, ext_bits(answer), flags.strip(), rounding_mode)
        dest_file.write(translation + "\n")
    dest_file.close()
    src_file.close()