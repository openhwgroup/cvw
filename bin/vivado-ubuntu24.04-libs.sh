#!/bin/bash

# Rose Thompson rose@rosethompson.net
# Oct 29, 2024
# Downloads libncurses5 and libtinfo5 from ubuntu 22.04, extracts the libraries and installs to the system.  Requires root.

# A component of the CORE-V-WALLY configurable RISC-V project.
# https://github.com/openhwgroup/cvw
#
# Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
#
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
#
# Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
# except in compliance with the License, or, at your option, the Apache License version 2.0. You 
# may obtain a copy of the License at
#
# https://solderpad.org/licenses/SHL-2.1/
#
# Unless required by applicable law or agreed to in writing, any work distributed under the 
# License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
# either express or implied. See the License for the specific language governing permissions 
# and limitations under the License.

TmpDir=$(mktemp -d )
echo $TmpDir

cd $TmpDir

wget http://security.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2ubuntu0.1_amd64.deb
wget http://security.ubuntu.com/ubuntu/pool/universe/n/ncurses/libncurses5_6.3-2ubuntu0.1_amd64.deb

dpkg-deb -xv libtinfo5_6.3-2ubuntu0.1_amd64.deb ./libtinfo5
dpkg-deb -xv libncurses5_6.3-2ubuntu0.1_amd64.deb ./libncurses5

echo "Installing libraries."
sudo cp libncurses5/lib/x86_64-linux-gnu/* /usr/lib/x86_64-linux-gnu/
sudo cp libncurses5/usr/lib/x86_64-linux-gnu/* /usr/lib/x86_64-linux-gnu/
sudo cp libtinfo5/lib/x86_64-linux-gnu/* /usr/lib/x86_64-linux-gnu/
sudo cp libtinfo5/usr/lib/x86_64-linux-gnu/* /usr/lib/x86_64-linux-gnu/
sudo cp -r libtinfo5/usr/share/doc/* /usr/share/doc/
sudo ln -f -s /usr/share/doc/libtinfo5/ /usr/share/doc/libncurses5

cd -

echo "Removing temporary files."
rm -rf $TmpDir

echo "Finished."



