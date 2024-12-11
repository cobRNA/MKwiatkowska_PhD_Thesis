#!/usr/bin/env bash

######################################################################################
# Raw Danio Rerio annotations were downloaded into /Data/Source/Annotations/
# Here annotations are processed to contatain only lncRNAs data.
# Data was also reformatted if necessary.

# Summary:
##########################################################################################
## - Remove patches and chrUn (after LiftOver);
## - Removed dot strands (present in ZFLNC);
## - ZFLNC do not contain chrM;
##########################################################################################


##########################################################################################
# Remove files from previous run
##########################################################################################
rm -r ./Data/lncRNA_catalogs/output/
rm -r ./Data/lncRNA_catalogs/.temp/


##########################################################################################
# Create directory treee
##########################################################################################
mkdir ./Data/lncRNA_catalogs/output/
mkdir ./Data/lncRNA_catalogs/.temp/


##########################################################################################
# Handle errors
##########################################################################################
set -e          # exit on any non-0 exit status
set -o pipefail # exit on any non-0 exit status in pipe


##########################################################################################
# Create LOG file
##########################################################################################
printf -v date '%(%Y-%m-%d_%H:%M)T' -1   # write current date to $date variable
LOG_LOCATION=./Logs/lncRNA_catalogs.$date.log
exec > >(tee -i $LOG_LOCATION)
exec 2>&1

echo "Log saved to: [ $LOG_LOCATION ]"


##########################################################################################
# Go to working directory
##########################################################################################
cd ./Data/lncRNA_catalogs/.temp/


##########################################################################################
# Copy files
##########################################################################################
# Copy catalogs to temp dir
cp ../../Source/Annotations/*gtf.gz .


##########################################################################################
# Download additional files
##########################################################################################
echo -e "+++ Downloading additional files: RefSeq chr decoder +++"
# Chromosome decoder for RefSeq
## main chromosomes
wget -O main_chr2acc "https://ftp.ncbi.nlm.nih.gov/refseq/D_rerio/annotation_releases/106/GCF_000002035.6_GRCz11/GCF_000002035.6_GRCz11_assembly_structure/Primary_Assembly/assembled_chromosomes/chr2acc"

## chrM
wget -O mito_chr2acc "https://ftp.ncbi.nlm.nih.gov/refseq/D_rerio/annotation_releases/106/GCF_000002035.6_GRCz11/GCF_000002035.6_GRCz11_assembly_structure/non-nuclear/assembled_chromosomes/chr2acc"
echo "---- DONE ----"

##########################################################################################
# Process
##########################################################################################

#######################
# Ensembl 
#######################
echo -e "+++ Processing: Ensembl +++"

## 104 relase
zcat ensembl104_GRCz11.gtf.gz | awk '$3=="gene"' | grep -Ew "antisense|lincRNA|processed_transcript|sense_intronic|sense_overlapping" | ../../../Utils/extract.gtf.tags.sh - gene_id | grep "\S"  > ensembl104_GRCz11_lncRNA_gene.ids
zcat ensembl104_GRCz11.gtf.gz | grep -Fwf ensembl104_GRCz11_lncRNA_gene.ids | awk -F"\t" '{OFS=FS} $1="chr"$1' | sed 's/chrMT/chrM/g' | awk '$1 ~ /^chr[0-9XYM]{1,2}$/ {print $0}' | ../../../Utils/gff2gff.pl - | grep "\S" | gzip > ../output/ensembl104_GRCz11_lncRNA.gtf.gz

## 113 relase (latest)
zcat ensembl113_GRCz11.gtf.gz | awk '$3=="gene"' | grep -Ew "antisense|lincRNA|processed_transcript|sense_intronic|sense_overlapping" | ../../../Utils/extract.gtf.tags.sh - gene_id | grep "\S"  > ensembl113_GRCz11_lncRNA_gene.ids
zcat ensembl113_GRCz11.gtf.gz | grep -Fwf ensembl113_GRCz11_lncRNA_gene.ids | awk -F"\t" '{OFS=FS} $1="chr"$1' | sed 's/chrMT/chrM/g' | awk '$1 ~ /^chr[0-9XYM]{1,2}$/ {print $0}' | ../../../Utils/gff2gff.pl - | grep "\S" | gzip > ../output/ensembl113_GRCz11_lncRNA.gtf.gz
echo "---- DONE ----"

#######################
# RefSeq
#######################
echo -e "+++ Processing: RefSeq +++"

## Decode chromosomes
### Remove header and concatenate
cat main_chr2acc mito_chr2acc | grep -v "#" > chr2acc
### Rename chromosomes in RefSeq annotation according to chr2acc file (only main and mito chromosomes)
while read chr code || [ -n "$chr" ]  # solution to no terminal newline problem
do  
    zcat refseq_GRCz11.gtf.gz | grep -F "$code" | sed "s/$code/chr${chr}/g" | sed 's/chrMT/chrM/g' | gzip >> refseq_GRCz11_chr.gtf.gz
done < chr2acc

## Pick only lncRNAs
### Extract lncRNA genes
zcat refseq_GRCz11_chr.gtf.gz | awk '$3=="gene"' | grep -Ew "gene_biotype \"antisense_RNA\";|gene_biotype \"lncRNA\";" | ../../../Utils/extract.gtf.tags.sh - gene_id | grep "\S" > refseq_GRCz11_lncRNA_gene.ids
zcat refseq_GRCz11_chr.gtf.gz | grep -Fwf refseq_GRCz11_lncRNA_gene.ids | grep "\S" | gzip > ../output/refseq_GRCz11_lncRNA.gtf.gz
echo "---- DONE ----"


#######################
# lncRbase
#######################
echo -e "+++ Processing: lncRbase +++"

# Select only exons and transcripts
zcat lncRbaseV2_GRCz10.gtf.gz | awk '$3=="exon"||$3=="transcript"' | grep "\S" | gzip > lncRbaseV2_GRCz10_lncRNA.gtf.gz

# LifOver to GRCz11
## Convert to bed
zcat lncRbaseV2_GRCz10_lncRNA.gtf.gz | ../../../Utils/gff2bed_full.pl - > lncRbaseV2_GRCz10_lncRNA.bed12

## LiftOver
../../../Utils/LiftOver/liftOver lncRbaseV2_GRCz10_lncRNA.bed12 ../../../Utils/LiftOver/danRer10ToDanRer11.over.chain.gz lncRbaseV2_GRCz11_lncRNA.bed12 lncRbaseV2.unMapped

## Convert back to gtf
cat lncRbaseV2_GRCz11_lncRNA.bed12 | awk '$1 ~ /^chr[0-9XYM]{1,2}$/ {print $0}' | ../../../Utils/bed12togff - | ../../../Utils/gff2gff.pl - | grep "\S" | gzip > ../output/lncRbaseV2_GRCz11_lncRNA.gtf.gz
echo "---- DONE ----"

#######################
# ZFLNC
#######################
echo -e "+++ Processing: ZFLNC +++"

# LifOver to GRCz11
## Convert to bed
zcat ZFLNC_Zv9_lncRNA.gtf.gz | ../../../Utils/gff2bed_full.pl - > ZFLNC_Zv9_lncRNA.bed12

## LiftOver
../../../Utils/LiftOver/liftOver ZFLNC_Zv9_lncRNA.bed12 ../../../Utils/LiftOver/danRer7ToDanRer11.over.chain.gz ZFLNC_GRCz11_lncRNA.bed12 ZFLNC.unMapped

## Convert back to gtf
cat ZFLNC_GRCz11_lncRNA.bed12 | awk '$1 ~ /^chr[0-9XYM]{1,2}$/ {print $0}' | awk 'BEGIN{FS=OFS="\t"}$6!="."' | ../../../Utils/bed12togff - | ../../../Utils/gff2gff.pl - | grep "\S" | gzip > ../output/ZFLNC_GRCz11_lncRNA.gtf.gz
echo "---- DONE ----"










# ("antisense_RNA")
# ("non_coding")
# ("bidirectional_promoter_lncrna")
# ("bidirectional_promoter_lncRNA")
# ("macro_lncRNA")
# ("lincRNA")
# ("processed_transcript")
# ("sense_intronic")
# ("sense_overlapping")


# antisense_RNA lncRNA 







# Remove .temp dir
#cd -
#rm -r ./Data/lncRNA_catalogs/.temp/

# Report completeness
echo "######### COMPLETED #########"
