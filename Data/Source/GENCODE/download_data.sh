#!/usr/bin/env bash

echo '@ Downloading GENCODE data files ++++++'

# Change dir
cd ./Data/Source/GENCODE/

# Download gencode.v47.pc_transcripts
wget "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_47/gencode.v47.pc_transcripts.fa.gz"

# Download gencode.v47.lncRNA_transcripts
wget "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_47/gencode.v47.lncRNA_transcripts.fa.gz"

# Download GRCh38.primary_assembly.genome
wget "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_47/GRCh38.primary_assembly.genome.fa.gz"

# Return
cd -
