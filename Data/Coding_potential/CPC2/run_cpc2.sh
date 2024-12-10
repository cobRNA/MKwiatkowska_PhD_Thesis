#!/usr/bin/env bash

######################################################################################
# Run CPC2 for Zebrafish.



# Summary:
##########################################################################################
## - Prepare environment;
## - Convert input from gtf.gz to fasta;
## - Run CPC2.
##########################################################################################

##########################################################################################
# Remove files from previous run
##########################################################################################
rm -r ./Data/Coding_potential/CPC2/output/
rm -r ./Data/Coding_potential/CPC2/.temp/

##########################################################################################
# Create directory treee
##########################################################################################
mkdir ./Data/Coding_potential/CPC2/output/
mkdir ./Data/Coding_potential/CPC2/.temp/

##########################################################################################
# Handle errors
##########################################################################################
set -e          # exit on any non-0 exit status
set -o pipefail # exit on any non-0 exit status in pipe

##########################################################################################
# Create LOG file
##########################################################################################
printf -v date '%(%Y-%m-%d_%H:%M)T' -1   # write current date to $date variable
LOG_LOCATION=./Logs/cpc2.$date.log
exec > >(tee -i $LOG_LOCATION)
exec 2>&1

echo "Log saved to: [ $LOG_LOCATION ]"

##########################################################################################
# Processing
##########################################################################################
# Activate Python venv
source .venv_CPC2/bin/activate

# Change dir
cd ./Data/Coding_potential/CPC2/.temp/

# Define paths
## Gene file
gene_file="../../../Source/Ensembl/Danio_rerio.GRCz11.dna.primary_assembly.fa.gz"

# Convert input file from gtf.gz to fasta
echo "~~~~ Preparing input ~~~~"
## Extract gene file
zcat $gene_file > Danio_rerio.GRCz11.dna.primary_assembly.fa

## Process annotation by removing SIRVs, reformatting chr names and converting to bed file format
## Concatenation of all samples
zcat ../../../Tmerge/output/all_concatenated.gtf.gz | awk '$1!="SIRVome_isoforms"' | ../../../../Utils/gff2bed_full.pl - | sed 's/chrM/MT/g' | sed 's/chr//g' > all_concat.bed
## Tmerged ouput
zcat ../../../Tmerge/output/all_tmerged.gtf.gz | awk '$1!="SIRVome_isoforms"' | ../../../../Utils/gff2bed_full.pl - | sed 's/chrM/MT/g' | sed 's/chr//g' > all_tmerged.bed

## Convert bed to fasta:
bedtools getfasta -fi Danio_rerio.GRCz11.dna.primary_assembly.fa -bed all_concat.bed > all_concat.fa
bedtools getfasta -fi Danio_rerio.GRCz11.dna.primary_assembly.fa -bed all_tmerged.bed > all_tmerged.fa
echo "+++++ DONE +++++"

# Go to CPC2 software dir
cd ../CPC2_standalone-1.0.1/

# Run CPC2
echo "~~~~ Running CPC2 ~~~~"
echo ">>> Using concatenated file"
python ./bin/CPC2.py -i ../.temp/all_concat.fa -o ../.temp/concat_output
echo "+++ DONE +++"
echo ">>> Using tmerged file"
python ./bin/CPC2.py -i ../.temp/all_tmerged.fa -o ../.temp/tmerged_output
echo "+++ DONE +++"

# Remove # from header to make it easily compatible with R
cat ../.temp/concat_output.txt | sed 's/#//g' > ../output/concat_output.tsv
cat ../.temp/tmerged_output.txt | sed 's/#//g' > ../output/tmerged_output.tsv

# Get back
cd -

# Report on completion
echo "+++++ COMPLETED +++++"
