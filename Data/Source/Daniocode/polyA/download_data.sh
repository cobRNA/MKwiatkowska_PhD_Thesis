#!/usr/bin/env bash

echo '@ Downloading files ++++++'
# Chagne dir
cd ./Data/Source/Daniocode/polyA/

# Download data
wget -i DCC-urls.txt
for file in ./*bed; do gzip $file; done

# Return
cd -
