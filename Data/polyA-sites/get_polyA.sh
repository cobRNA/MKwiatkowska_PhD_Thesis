#!/usr/bin/env bash

######################################################################################
# Data were downloaded from Danio-Code website using filters:
# - file type: BED
# - library preparation: polyA
#Than saved as URL txt file.
#Files were downloaded into source directory using:
# ./Data/Source/Daniocode/polyA/download_data.sh

# Summary:
######################################################################################
## - There are multiple duplicated lines;
## - There are not only main chromosomes but also patches (awk '!seen[$1]++{print$1}');
## - chrM is present but chrX and chrY are not;
## - strand is correctly assign for all entries (awk 'BEGIN{FS=OFS="\t"}$6!="."');
######################################################################################

##########################################################################################
# Remove files from previous run
##########################################################################################
rm ./Data/polyA-sites/danRer11_polyAsites.bed.gz

##########################################################################################
# Handle errors
##########################################################################################
set -e          # exit on any non-0 exit status
set -o pipefail # exit on any non-0 exit status in pipe

##########################################################################################
# Create LOG file
##########################################################################################
printf -v date '%(%Y-%m-%d_%H:%M)T' -1   # write current date to $date variable
LOG_LOCATION=./Logs/polyA-sites.$date.log
exec > >(tee -i $LOG_LOCATION)
exec 2>&1

echo "Log saved to: [ $LOG_LOCATION ]"

##########################################################################################
# Processing
##########################################################################################
## Concatenated all files and removed duplicated lines
echo '@ Concatenating files and removing duplicates ++++++'
### 5th signal column is the source of multiple duplicated lines. Set all values to 0.
### tx-id is also problematic. Produce them from scratch.
### There are some entries like this:
### chrM    -1      0       chrM|-1|0|-     0       -
### Mostly for patches. I removed them manually.
zcat ./Data/Source/Daniocode/polyA/*bed.gz | awk 'BEGIN{FS=OFS="\t"}$5="0"' | awk 'BEGIN{FS=OFS="\t"}$2!="-1"' | awk 'BEGIN{FS=OFS="\t"}$4=$1"|"$2"|"$3"|"$6' | sort | uniq | ./Utils/sortbed - | gzip > ./Data/polyA-sites/danRer11_polyAsites.bed.gz

# Check file:
##########################################################################################
## Look for uncorrectly assigned strand
all_strand=`zcat ./Data/polyA-sites/danRer11_polyAsites.bed.gz | wc -l`
correct_strand=`zcat ./Data/polyA-sites/danRer11_polyAsites.bed.gz | awk 'BEGIN{FS=OFS="\t"}$6!="."' | wc -l`

set +e # This error handling may be problematic for if statements
echo '@ Checking for uncorrect strand sign ++++++'
corrupted_strand=$((all_strand-correct_strand))
if [ $corrupted_strand -gt 0 ]
then
    echo 'CORRUPTED ENTRIES DETECTED!!'
    echo "Detected $corrupted_strand entries with uncorrect strand!"
    exit 1
else
    echo 'Everything is fine. Not a single corrupted strand sign detected.'
fi
echo '>> Done <<'
set -e

##########################################################################################
## Look for duplicated entries
all_entries=`zcat ./Data/polyA-sites/danRer11_polyAsites.bed.gz | wc -l`
uniq_entries=`zcat ./Data/polyA-sites/danRer11_polyAsites.bed.gz | awk '{print $1, $2, $3, $6}'| sort | uniq | wc -l`

set +e # This error handling may be problematic for if statements
echo '@ Checking for duplicated entries ++++++'
duplicated_entries=$((all_entries-uniq_entries))
if [ $duplicated_entries -gt 0 ]
then
    echo 'CORRUPTED ENTRIES DETECTED!!'
    echo "Detected $duplicated_entries duplicated entries!"
    exit 1
else
    echo 'Everything is fine. Not a single duplicate detected.'
fi
echo '>> Done <<'
set -e

##########################################################################################
# Report completeness
echo "Everything seems fine. Processed and sorted bed is located in ./Data/polyA-sites/"
