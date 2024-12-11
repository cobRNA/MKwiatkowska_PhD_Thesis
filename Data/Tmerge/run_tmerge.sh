#!/usr/bin/env bash

######################################################################################
# Data were downloaded from Public Docs website:
# - https://public-docs.crg.es/rguigo/lncRNA_review/MK/lr/updated/trackHub/dataFiles/
# Files were removed after tmerge


# Summary:
##########################################################################################
## - Download .gtf.gz file;
## - Concatenate together;
## - Run tmerge;
## - Keep tmerged output but remove .temp files.
##########################################################################################

##########################################################################################
# Remove files from previous run
##########################################################################################
rm -r ./Data/Tmerge/output/

##########################################################################################
# Create directory treee
##########################################################################################
mkdir ./Data/Tmerge/output/
mkdir ./Data/Tmerge/.temp/

##########################################################################################
# Handle errors
##########################################################################################
set -e          # exit on any non-0 exit status
set -o pipefail # exit on any non-0 exit status in pipe

##########################################################################################
# Create LOG file
##########################################################################################
printf -v date '%(%Y-%m-%d_%H:%M)T' -1   # write current date to $date variable
LOG_LOCATION=./Logs/tmerge.$date.log
exec > >(tee -i $LOG_LOCATION)
exec 2>&1

echo "Log saved to: [ $LOG_LOCATION ]"

##########################################################################################
# Processing
##########################################################################################
# Change dir
cd ./Data/Tmerge/.temp/

# Run in the loop
while read file_url || [ -n "$file_url" ]
  do
      # Preapre name
      name=`echo $file_url |  awk -F'/' '{print $NF}' | awk -F'.' '{print $1}'`
      # Download
      echo "~~~ Downloading: $name ~~~"
      wget --quiet "$file_url"
      # Concatenate without extracting (and remove huge "contains" feature)
      zcat $name.tmerge.min2reads.gff.gz | ../../../Utils/gff2bed_full.pl - | ../../../Utils/bed12togff - | grep "\S" | gzip >> ../output/all_concatenated.gtf.gz
      # Clean up
      rm $name.tmerge.min2reads.gff.gz
  done < ../links.txt

# Check for duplicated entries on transcript level
set +e # This error handling may be problematic for if statements
echo '~~~ Checking for duplicated entries (on transcript level) ~~~'
all_entries=`zcat ../output/all_concatenated.gtf.gz | ../../../Utils/gff2bed_full.pl - | grep "\S" | wc -l`
uniq_entries=`zcat ../output/all_concatenated.gtf.gz | ../../../Utils/gff2bed_full.pl - | grep "\S" | sort | uniq | wc -l`
duplicated_entries=$((all_entries-uniq_entries))
if [ $duplicated_entries -gt 0 ]
then
    echo 'DUPLICATED ENTRIES DETECTED!!'
    echo "Detected $duplicated_entries duplicated entries!"
    exit 1
else
    echo 'Everything is fine. Not a single duplicate detected.'
fi
echo '>> Done <<'
set -e

# Run tmerge
echo "~~~ Tmerging... ~~~"
zcat ../output/all_concatenated.gtf.gz | ../../../Utils/sortgff - | ../../../Utils/tmerge --exonOverhangTolerance 8 --tmPrefix IC - | grep '\S' | gzip > ../output/all_tmerged.gtf.gz
  
# Remove .temp dir
cd -
rm -r ./Data/Tmerge/.temp/

# Report completeness
echo "######### COMPLETED #########"
