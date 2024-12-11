#!/usr/bin/env bash

echo '@ Downloading Ensembl data files ++++++'

# Change dir
cd ./Data/Source/Ensembl/

# Download Danio_rerio.GRCz11.dna.primary_assembly.fa.gz
wget "https://ftp.ensembl.org/pub/release-104/fasta/danio_rerio/dna/Danio_rerio.GRCz11.dna.primary_assembly.fa.gz"

# Download Danio_rerio.GRCz11.cds.all.fa.gz
wget "https://ftp.ensembl.org/pub/release-104/fasta/danio_rerio/cds/Danio_rerio.GRCz11.cds.all.fa.gz"

# Download Danio_rerio.GRCz11.ncrna.fa.gz
wget "https://ftp.ensembl.org/pub/release-104/fasta/danio_rerio/ncrna/Danio_rerio.GRCz11.ncrna.fa.gz"

# Download annotation: Danio_rerio.GRCz11.104.chr.gtf.gz
wget "https://ftp.ensembl.org/pub/release-104/gtf/danio_rerio/Danio_rerio.GRCz11.104.chr.gtf.gz"

# Return
cd -
