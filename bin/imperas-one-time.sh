#!/bin/bash
###########################################
## imperas-one-time.sh
##
## Written: Ross Thompson (ross1728@gmail.com) and Lee Moore (moore@imperas.com)
## Created: 31 January 2023
## Modified: 31 January 2023
##
## Purpose: One time setup script for running imperas.
## 
## A component of the CORE-V-WALLY configurable RISC-V project.
## 
## Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
##
## SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
##
## Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
## except in compliance with the License, or, at your option, the Apache License version 2.0. You 
## may obtain a copy of the License at
##
## https://solderpad.org/licenses/SHL-2.1/
##
## Unless required by applicable law or agreed to in writing, any work distributed under the 
## License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
## either express or implied. See the License for the specific language governing permissions 
## and limitations under the License.
################################################################################################


IMP_HASH=56b1479

# clone the Imperas repo
cd $WALY
if [ ! -d external ]; then
    mkdir -p external
fi
pushd external
    if [ ! -d ImperasDV-HMC ]; then
	git clone git@github.com:Imperas/ImperasDV-HMC.git
    fi
    pushd ImperasDV-HMC
    git checkout $IMP_HASH
    popd
popd

# Setup Imperas
source ${WALLY}/external/ImperasDV-HMC/Imperas/bin/setup.sh
setupImperas ${WALLY}/external/ImperasDV-HMC/Imperas
export IMPERAS_PERSONALITY=CPUMAN_DV_ASYNC

# setup QUESTA (Imperas only command, YMMV)
#svsetup -questa


