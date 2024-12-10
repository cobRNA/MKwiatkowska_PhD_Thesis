#!/usr/bin/env bash

######################################################################################
# Data were downloaded from Public Docs website:
# - https://public-docs.crg.es/rguigo/lncRNA_review/MK/lr/updated/trackHub/dataFiles/
# Files are too big to download them all and subsequently process.
# I downloaded them separately, transformed into bigwig and removed.
# In the same dir, thare are already .bam.bai files but they differ so it was better to 
# make them from the scratch.
# Used annotation is the same as used to LyRic run. Its located in /Source/LyRic/
# Edited to create both BigWigs and BigWigExonicRegions files

# Summary:
##########################################################################################
## - Download .bam file;
## - Transform according to LyRic pipeline (rules makeBigWigs AND makeBigWigExonicRegions from lrMapping.smk);
## - Remove downloaded file;
## - Keep bigwig output.
##########################################################################################

##########################################################################################
# Remove files from previous run
##########################################################################################
rm -r ./Data/BigWigs/makeBigWigExonicRegions_output/
rm -r ./Data/BigWigs/makeBigWigs_output/

##########################################################################################
# Create directory treee
##########################################################################################
mkdir ./Data/BigWigs/makeBigWigExonicRegions_output/
mkdir ./Data/BigWigs/makeBigWigs_output/
mkdir ./Data/BigWigs/.temp/

##########################################################################################
# Handle errors
##########################################################################################
set -e          # exit on any non-0 exit status
set -o pipefail # exit on any non-0 exit status in pipe

##########################################################################################
# Create LOG file
##########################################################################################
printf -v date '%(%Y-%m-%d_%H:%M)T' -1   # write current date to $date variable
LOG_LOCATION=./Logs/makeBigWigs.$date.log
exec > >(tee -i $LOG_LOCATION)
exec 2>&1

echo "Log saved to: [ $LOG_LOCATION ]"

##########################################################################################
# Processing
##########################################################################################
# Change dir
cd ./Data/BigWigs/.temp/

# Extract exons from annotation
zcat ../../Source/LyRic/ERCC+ensembl.104+SIRV_with_gene_rec.gtf.gz | awk '$3=="exon"' > annotation_exons.gff

# Run in the loop
while read file_url || [ -n "$file_url" ]
  do
      name=`echo $file_url |  awk -F'/' '{print $NF}' | awk -F'.' '{print $1}'`
      echo "~~~ Downloading: $name ~~~"
      wget --quiet "$file_url"
      # Run bedtools intersect (required for exonicRegions)
      echo "~~~ Intersecting ~~~"
      bedtools intersect -split -u -a ${name}.bam -b annotation_exons.gff > ${name}_intersected.bam
      echo "+++ Done +++"
      # Run indexing
      echo "~~~ Indexing bam file ~~~"
      samtools index ${name}_intersected.bam
      samtools index ${name}.bam
      echo "+++ Done +++"
      # Create bigwig files
      echo "~~~ Creating bigwig ~~~"
      bamCoverage --numberOfProcessors max/2 --normalizeUsing CPM  -b ${name}_intersected.bam -o ../makeBigWigExonicRegions_output/${name}.bw
      bamCoverage --numberOfProcessors max/2 --normalizeUsing CPM -b ${name}.bam -o ../makeBigWigs_output/${name}.bw
      echo "+++ Done +++"
      # Clean up
      rm ${name}.bam
      rm ${name}.bam.bai
      rm ${name}_intersected.bam
      rm ${name}_intersected.bam.bai
  done < ../links.txt

# Remove .temp dir
cd -
rm -r ./Data/BigWigs/.temp/

# Report completeness
echo "######### COMPLETED #########"
