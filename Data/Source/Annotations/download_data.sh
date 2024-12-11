#!/usr/bin/env bash

##########################################################################################
# Handle errors
##########################################################################################
set -e          # exit on any non-0 exit status
set -o pipefail # exit on any non-0 exit status in pipe
##########################################################################################

echo '@ Downloading zebrafish annotation data files ++++++'

# Change dir
cd ./Data/Source/Annotations/

#######################
# Ensembl
#######################
# Download older Ensembl annotation (release 104; GRCz11)
wget -O ensembl104_GRCz11.gtf.gz "https://ftp.ensembl.org/pub/release-104/gtf/danio_rerio/Danio_rerio.GRCz11.104.chr.gtf.gz"
# Download the latest Ensembl annotation (release 113; GRCz11)
wget -O ensembl113_GRCz11.gtf.gz "https://ftp.ensembl.org/pub/release-113/gtf/danio_rerio/Danio_rerio.GRCz11.113.chr.gtf.gz"

#######################
# RefSeq
#######################
# Download the latest RefSeq annotation (release 106; GRCz11)
## Annotation
#wget "https://ftp.ncbi.nlm.nih.gov/refseq/D_rerio/annotation_releases/GCF_000002035.6-RS_2024_08/GCF_000002035.6_GRCz11_genomic.gtf.gz"
wget -O refseq_GRCz11.gtf.gz "https://ftp.ncbi.nlm.nih.gov/refseq/D_rerio/annotation_releases/106/GCF_000002035.6_GRCz11/GCF_000002035.6_GRCz11_genomic.gtf.gz"

#######################
# ZFLNC
#######################
# Download the latest ZFLNC annotation (Zv9)
wget "https://www.biochen.org/zflnc/static/download/ZFLNC_lncRNA.gtf.zip"
unzip ZFLNC_lncRNA.gtf.zip
rm ZFLNC_lncRNA.gtf.zip
gzip ZFLNC_lncRNA.gtf
mv ZFLNC_lncRNA.gtf.gz ZFLNC_Zv9_lncRNA.gtf.gz

#######################
# lncRbase
#######################
# Download the latest lncRbase annotation (v.2; GRCz10) <- server is shitty, try multiple times
wget --tries=0 -O lncRbaseV2_GRCz10.gtf "http://dibresources.jcbose.ac.in/zhumur/lncrbase2/download/zebrafish_gtf.gtf"
gzip lncRbaseV2_GRCz10.gtf

#######################
# NONCODE
#######################
# Download the latest NONCODE annotation ()

#######################
# zflncRNApedia
#######################
# Download the latest zflncRNApedia annotation (XX; Zv9?)

# Report completeness
echo "######### COMPLETED #########"

# Return
cd -
