#!/bin/bash

removePacks=( '^llvm-.*' 'php.*' '^mongodb-.*' '^mysql-.*' '^dotnet-sdk-.*' 'azure-cli' 'google-cloud-cli' 'google-chrome-stable' 'firefox' 'powershell*' 'microsoft-edge-stable' 'mono-devel' )
for pack in "${removePacks[@]}"; do
  echo "REMOVING ${pack}"
  sudo apt-get purge -y $pack || true
done
sudo apt-get autoremove -y
sudo apt-get clean
