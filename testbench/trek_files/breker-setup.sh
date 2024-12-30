#!/bin/bash
export BREKER_ARCH=${BREKER_HOME}/linux64
export PATH=${BREKER_HOME}/bin:${BREKER_HOME}/examples/tutorials/apps/coherency/bin:${PATH}
export LD_LIBRARY_PATH=".:${BREKER_ARCH}/lib:${BREKER_HOME}/opensrc/gcc/lib:${BREKER_HOME}/opensrc/gcc/lib64":${LD_LIBRARY_PATH}
export LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/:$LIBRARY_PATH
