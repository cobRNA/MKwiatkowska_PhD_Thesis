#!/usr/bin/env bash

echo '@ Downloading files ++++++'
# Chagne dir
cd ./Data/Source/Daniocode/CAGE/

# Multiple links are duplicated after downloading from Daniocode
# To save time it's good to remove duplicates
cat DCC-urls.txt | sort | uniq > DCC-urls_uniq.txt

# Download data in the loop
while read file_url || [ -n "$file_url" ]
  do
      # Preapre name
      file=`echo $file_url |  awk -F'/' '{print $NF}'`
      # Download
      echo "~~~ Downloading: $file ~~~"
      wget --quiet "$file_url"
      # Compress inplace
      gzip $file
  done < DCC-urls_uniq.txt

# Return
cd -
