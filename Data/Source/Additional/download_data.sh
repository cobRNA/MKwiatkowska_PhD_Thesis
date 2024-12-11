#!/usr/bin/env bash

# Handle errors
set -e          # exit on any non-0 exit status
set -o pipefail # exit on any non-0 exit status in pipe

echo '@ Downloading additional data files ++++++'

# Change dir
cd ./Data/Source/Additional/

# Download danRer11 chromosome sizes
wget "https://hgdownload.soe.ucsc.edu/goldenPath/danRer11/bigZips/danRer11.chrom.sizes"

# Download hg38 chromosome sizes
wget "https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.chrom.sizes"

# Download hg38 polyA signals
wget "https://public-docs.crg.es/rguigo/Papers/2017_lagarde-uszczynska_CLS/data/polyA/signals/hg38.polyAsignals.bed.gz"

# Download latest Human GENCODE annotation (lncRNA)
wget "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_47/gencode.v47.long_noncoding_RNAs.gtf.gz"

# Download latest Human GENCODE annotation (Comprehensive)
wget "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_47/gencode.v47.annotation.gtf.gz"

# Download latest Mouse GENCODE annotation (lncRNA)
wget "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_mouse/release_M36/gencode.vM36.long_noncoding_RNAs.gtf.gz"

# Download latest Mouse GENCODE annotation (Comprehensive)
wget "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_mouse/release_M36/gencode.vM36.annotation.gtf.gz"

# Report completeness
echo "###### COMPLETED ######"
