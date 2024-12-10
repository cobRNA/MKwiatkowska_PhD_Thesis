#!/usr/bin/env bash

######################################################################################
#



# Summary:
##########################################################################################
## - Prepare environment;
## - Create hexamer table;
## - Build logit model;
## - Run CPAT.
##########################################################################################

##########################################################################################
# Remove files from previous run
##########################################################################################
rm -r ./Data/Coding_potential/CPAT/output/
rm -r ./Data/Coding_potential/CPAT/.temp/

##########################################################################################
# Create directory treee
##########################################################################################
mkdir ./Data/Coding_potential/CPAT/output/
mkdir ./Data/Coding_potential/CPAT/.temp/

##########################################################################################
# Handle errors
##########################################################################################
set -e          # exit on any non-0 exit status
set -o pipefail # exit on any non-0 exit status in pipe

##########################################################################################
# Create LOG file
##########################################################################################
printf -v date '%(%Y-%m-%d_%H:%M)T' -1   # write current date to $date variable
LOG_LOCATION=./Logs/cpat.$date.log
exec > >(tee -i $LOG_LOCATION)
exec 2>&1

echo "Log saved to: [ $LOG_LOCATION ]"

##########################################################################################
# Processing
##########################################################################################
# Activate Python venv
source .venv/bin/activate

# Change dir
cd ./Data/Coding_potential/CPAT/.temp/

# Define paths
## Coding sequence (CDS without UTR)
CDS_file="../../../Source/Ensembl/Danio_rerio.GRCz11.cds.all.fa.gz"
## NonCoding sequence
ncRNA_file="../../../Source/Ensembl/Danio_rerio.GRCz11.ncrna.fa.gz"
## Gene file
gene_file="../../../Source/Ensembl/Danio_rerio.GRCz11.dna.primary_assembly.fa.gz"

# Create hexamer table
echo "~~~~ Creating hexamer table ~~~~"
make_hexamer_tab -c $CDS_file -n $ncRNA_file > Zebrafish_Hexamer.tsv
echo "+++ DONE +++"

# Build logit model
echo "~~~~ Building logit model ~~~~"
make_logitModel -x Zebrafish_Hexamer.tsv -c $CDS_file -n $ncRNA_file --log-file=../../../../Logs/make_logitModel_run_info.log -o Zebrafish
echo "+++ DONE +++"

# Extract gene file
zcat $gene_file > Danio_rerio.GRCz11.dna.primary_assembly.fa

# Process annotation by removing SIRVs, reformatting chr names and converting to bed file format
## Concatenation of all samples
zcat ../../../Tmerge/output/all_concatenated.gtf.gz | awk '$1!="SIRVome_isoforms"' | ../../../../Utils/gff2bed_full.pl - | sed 's/chrM/MT/g' | sed 's/chr//g' > all_concat.bed
## Tmerged ouput
zcat ../../../Tmerge/output/all_tmerged.gtf.gz | awk '$1!="SIRVome_isoforms"' | ../../../../Utils/gff2bed_full.pl - | sed 's/chrM/MT/g' | sed 's/chr//g' > all_tmerged.bed

# Run CPAT
echo "~~~~ Running CPAT ~~~~"
echo ">>> Using concatenated file"
cpat -x Zebrafish_Hexamer.tsv -d Zebrafish.logit.RData --top-orf=100 --antisense -g all_concat.bed -r Danio_rerio.GRCz11.dna.primary_assembly.fa -o ../output/concat
echo "+++ DONE +++"
echo ">>> Using tmerged file"
cpat -x Zebrafish_Hexamer.tsv -d Zebrafish.logit.RData --top-orf=100 --antisense -g all_tmerged.bed -r Danio_rerio.GRCz11.dna.primary_assembly.fa -o ../output/tmerged
echo "+++ DONE +++"


# Clean up to save some space
rm Danio_rerio.GRCz11.dna.primary_assembly.fa

# Get back
cd -
