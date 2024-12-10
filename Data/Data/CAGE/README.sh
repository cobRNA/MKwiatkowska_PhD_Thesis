#!/usr/bin/env bash

######################################################################################
# Data were downloaded from Danio-Code website using filters:
# - file type: BED
# - assay type: CAGE
# - genome version: danRer11
#Than saved as URL txt file.
#Files were downloaded into source directory using:
# ./Data/Source/Daniocode/CAGE/download_data.sh

# Summary:
######################################################################################
## - There are multiple duplicated lines;
## - Some files are not bed files - strand sign in $2. Those files should be excluded.
## - Some entries contains strage chr names: e.g. chrchr. I substituted all chrchr with chr;
## - Patches were excluded;
## - Strand is correctly assign for all entries (awk 'BEGIN{FS=OFS="\t"}$6!="."');
######################################################################################

##########################################################################################
# Remove files from previous run
##########################################################################################
rm -r ./Data/CAGE/.temp/
rm ./Data/CAGE/danRer11_CAGE.bed.gz

##########################################################################################
# Create dir structure
##########################################################################################
mkdir ./Data/CAGE/.temp/

##########################################################################################
# Handle errors
##########################################################################################
set -e          # exit on any non-0 exit status
set -o pipefail # exit on any non-0 exit status in pipe

##########################################################################################
# Create LOG file
##########################################################################################
printf -v date '%(%Y-%m-%d_%H:%M)T' -1   # write current date to $date variable
LOG_LOCATION=./Logs/cage.$date.log
exec > >(tee -i $LOG_LOCATION)
exec 2>&1

echo "Log saved to: [ $LOG_LOCATION ]"

##########################################################################################
# Processing
##########################################################################################
## Change dir
cd ./Data/CAGE/.temp/

echo '@ Processing files ++++++'
## Concatenated all files and and keep only main chromosomes (reformat to use tab as separator - {$1=$1}1 is crucial, awk only reformats if line is changed)
zcat ../../Source/Daniocode/CAGE/*bed.gz | awk '{gsub("^chrchr", "chr", $1); print }' | awk '$1 ~ /^chr[0-9XYM]{1,2}$/ {print $0}' | awk 'BEGIN {OFS="\t"} {$1=$1}1' | gzip > all_main_pseudo.bed.gz
## Extract good looking bed; replace $5 with 0; ADD to file
## I tried to use not bed-like files but it's only a waste of time. Contains the same info at best but easy to include junk and overmerge later (some entries are extra long).
zcat all_main_pseudo.bed.gz | awk '($2!="+") && ($2!="-") && ($2!=".")' | awk '{print $1"\t"$2"\t"$3"\t"$1":"$2"-"$3","$6"\t0\t"$6}' | sort | uniq | gzip > all_main.bed.gz
echo '>> Done <<'

# Check file:
##########################################################################################
## Look for uncorrectly assigned strand
all_strand=`zcat all_main.bed.gz | wc -l`
correct_strand=`zcat all_main.bed.gz | awk 'BEGIN{FS=OFS="\t"}$6!="."' | wc -l`

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

## Check if $6 contains strand sign
set +e # This error handling may be problematic for if statements
echo '@ Checking for missing strand sign in 6th column ++++++'
corrupted_strand_col=`zcat all_main.bed.gz | awk '($6!="+") && ($6!="-")' | wc -l`
if [ $corrupted_strand_col -gt 0 ]
then
    echo 'CORRUPTED ENTRIES DETECTED!!'
    echo "Detected $corrupted_strand_col entries without strand sign in 6th column!"
    exit 1
else
    echo 'Everything is fine. All entries contains strand sign in 6th column.'
fi
echo '>> Done <<'
set -e

## Look for entries with $2 > $3
set +e # This error handling may be problematic for if statements
echo '@ Checking for uncorrect coordinates (start > stop) ++++++'
corrupted_coordinates=`zcat all_main.bed.gz | awk '$2>$3' | wc -l`
if [ $corrupted_coordinates -gt 0 ]
then
    echo 'CORRUPTED ENTRIES DETECTED!!'
    echo "Detected $corrupted_scoordinates entries with bad coordinates (start > stop)!"
    exit 1
else
    echo 'Everything is fine. Not a single corrupted entry detected.'
fi
echo '>> Done <<'
set -e

# Merge using bedtools merge
echo '@ Merging signals using bedtoold merge ++++++'
zcat all_main.bed.gz | sort -k1,1 -k2,2n -k3,3n | bedtools merge -s -d 10 -c 5,6 -o sum,distinct -i - |  awk '{print $1"\t"$2"\t"$3"\t"$1":"$2"-"$3","$5"\t"$4"\t"$5}' | gzip > ../danRer11_CAGE.bed.gz
echo '>> Done <<'

##########################################################################################
# Report completeness
echo "Everything seems fine. Processed and merged bed is located in ./Data/CAGE/"
