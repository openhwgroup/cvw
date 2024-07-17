#!/bin/bash
###########################################
## GitHub runner space cleanup
##
## Written: Jordan Carlin, jcarlin@hmc.edu
## Created: 30 June 2024
## Modified:
##
## Purpose: Remove unnecessary packages/directories from GitHub Actions runner

## A component of the CORE-V-WALLY configurable RISC-V project.
## https://github.com/openhwgroup/cvw
##
## Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
##
## SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
##
## Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file
## except in compliance with the License, or, at your option, the Apache License version 2.0. You
## may obtain a copy of the License at
##
## https:##solderpad.org/licenses/SHL-2.1/
##
## Unless required by applicable law or agreed to in writing, any work distributed under the
## License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
## either express or implied. See the License for the specific language governing permissions
## and limitations under the License.
################################################################################################

# Remove unnecessary packages
removePacks=( '^llvm-.*' 'php.*' '^mongodb-.*' '^mysql-.*' '^dotnet-sdk-.*' 'azure-cli' 'google-cloud-cli' 'google-chrome-stable' 'firefox' '^powershell*' 'microsoft-edge-stable' 'mono-devel' 'hhvm' )
for pack in "${removePacks[@]}"; do
  sudo apt-get purge -y $pack &> /dev/null || true
done
sudo apt-get autoremove -y &> /dev/null || true
sudo apt-get clean &> /dev/null || true

# Remove unnecessary directories
sudo rm -rf /usr/local/lib/android &> /dev/null
sudo rm -rf /usr/share/dotnet &> /dev/null
sudo rm -rf /usr/share/swift &> /dev/null
sudo rm -rf /usr/share/miniconda &> /dev/null
sudo rm -rf /usr/share/az* &> /dev/null
sudo rm -rf /usr/share/gradle-* &> /dev/null
sudo rm -rf /usr/share/sbt &> /dev/null
sudo rm -rf /opt/ghc &> /dev/null
sudo rm -rf /usr/local/.ghcup &> /dev/null
sudo rm -rf /usr/local/share/powershell &> /dev/null
sudo rm -rf /usr/local/lib/node_modules &> /dev/null
sudo rm -rf /usr/local/julia* &> /dev/null
sudo rm -rf /usr/local/share/chromium &> /dev/null
sudo rm -rf /usr/local/share/vcpkg &> /dev/null
sudo rm -rf /usr/local/games &> /dev/null
sudo rm -rf /usr/local/sqlpackage &> /dev/null
sudo rm -rf /usr/lib/google-cloud-sdk &> /dev/null
sudo rm -rf /usr/lib/jvm &> /dev/null
sudo rm -rf /usr/lib/mono &> /dev/null
sudo rm -rf /usr/lib/R &> /dev/null
sudo rm -rf /usr/lib/postgresql &> /dev/null
sudo rm -rf /usr/lib/heroku &> /dev/null
sudo rm -rf /usr/lib/llvm* &> /dev/null
sudo rm -rf /usr/lib/firefox &> /dev/null
sudo rm -rf /opt/hostedtoolcache &> /dev/null

# Clean up docker images
sudo docker image prune --all --force &> /dev/null
