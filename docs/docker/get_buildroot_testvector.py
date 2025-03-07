import os
import shutil

# if WALLY is defined, then get it
WALLY_HOME = os.getenv("WALLY")
if WALLY_HOME is None or WALLY_HOME == "":
    # otherwise, it is assumed as ../../
    WALLY_HOME = "../../"

BUILDROOT_SRC = "linux/buildroot-config-src/wally"
TESTVECTOR_SRC = "linux/testvector-generation"

shutil.copytree(os.path.join(WALLY_HOME, BUILDROOT_SRC), "./buildroot-config-src")
shutil.copytree(os.path.join(WALLY_HOME, TESTVECTOR_SRC), "./testvector-generation")
