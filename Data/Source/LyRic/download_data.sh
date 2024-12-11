#!/usr/bin/env bash

# Handle errors
set -e          # exit on any non-0 exit status
set -o pipefail # exit on any non-0 exit status in pipe

echo '@ Downloading input/output from Danio LyRic run ++++++'

# Change dir
cd ./Data/Source/LyRic/

# Download annotation used in LyRic
wget "https://public-docs.crg.es/rguigo/lncRNA_review/TM/ERCC+ensembl.104+SIRV_with_gene_rec.gtf"

## Compress
gzip ERCC+ensembl.104+SIRV_with_gene_rec.gtf

############################
##### gff-compare output
############################
# Make temp/ and output/ dirs
mkdir temp
mkdir gff_compare

# Change dir
cd ./temp

# Download gff-compare output
wget "https://public-docs.crg.es/rguigo/lncRNA_review/tmp/cls/gffcompare.zip"

# Decompress
unzip gffcompare.zip

# Run in the loop
while read sample_name || [ -n "$sample_name" ]
  do
      # Prepare name
      name=`echo -e "${sample_name}.tmerge.min2reads.splicing_status-all.endSupport-all.vs.gencode.simple.tsv"`
      #name=`echo -e "${sample_name}.tmerge.min2reads.splicing_status-all.endSupport-all.vs.gencode.refmap"`
      # Find file recursively and move to output directory
      find . -name $name -exec mv '{}' "../gff_compare/" ";"
  done < ../trueSamples.info

# Change dir
cd ..

# Remove temp/ dir
rm -r ./temp/

# Report on completion
echo "+++++ COMPLETED +++++"
