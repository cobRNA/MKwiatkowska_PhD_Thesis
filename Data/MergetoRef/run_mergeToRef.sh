#!/usr/bin/env bash

######################################################################################
# Run merge to reference Ensembl annotation to get biotypes.



# Summary:
##########################################################################################
## - Merge tmeged transcripts with ensembl annotation;
## - Build loci using buildLoci;
## - Run mergeToRef script;
##########################################################################################

##########################################################################################
# Remove files from previous run
##########################################################################################
rm -r ./Data/MergeToRef/output/
rm -r ./Data/MergeToRef/.temp/

##########################################################################################
# Create directory treee
##########################################################################################
mkdir ./Data/MergeToRef/output/
mkdir ./Data/MergeToRef/.temp/

##########################################################################################
# Handle errors
##########################################################################################
set -e          # exit on any non-0 exit status
set -o pipefail # exit on any non-0 exit status in pipe

##########################################################################################
# Create LOG file
##########################################################################################
printf -v date '%(%Y-%m-%d_%H:%M)T' -1   # write current date to $date variable
LOG_LOCATION=./Logs/mergeToRef.$date.log
exec > >(tee -i $LOG_LOCATION)
exec 2>&1

echo "Log saved to: [ $LOG_LOCATION ]"

##########################################################################################
# Processing
##########################################################################################
# Change dir
cd ./Data/MergeToRef/.temp/

# Copy/Transfrom input data
echo "~~~~~ Copying data ~~~~~"
## concatenated (remove unnecessary tags and sirvs)
cp  ../../Tmerge/output/all_concatenated.gtf.gz .
## Ids of lncRNAs (CPAT & CPC2 intersection)
cp ../../Coding_potential/CPAT_intersect_CPC2_noncoding.tsv .
## Ensembl annotation with reformatted $1
zcat ../../Source/Ensembl/Danio_rerio.GRCz11.104.chr.gtf.gz | ../../../Utils/skipcomments | sed 's/^/chr/' | sed 's/chrMT/chrM/g' | awk '$3=="exon"' | sed 's/gene_biotype/gene_type/g' | ../../../Utils/gff2gff.pl - > Danio_rerio.GRCz11.104.chr_formatted.gtf
echo "+++ DONE +++"

# Transform data
echo "~~~~~ Transforming data ~~~~~"
## Reformat concatenated (remove unnecessary tags and sirvs)
zcat all_concatenated.gtf.gz | ../../../Utils/gff2bed_full.pl - |  ../../../Utils/bed12togff - | awk '$1 ~ /^chr[0-9XYM]{1,2}$/ {print $0}' | gzip > all_concat_formatted.gtf.gz
## Extract only tx_ids from CPAT & CPC2 intersection tsv (remove header)
cat CPAT_intersect_CPC2_noncoding.tsv | awk 'NR>1 {print $1}' > CPAT_intersect_CPC2_noncoding.ids
## Extract only lncRNAs from reformatted concatenated
zcat all_concat_formatted.gtf.gz | grep -Fwf CPAT_intersect_CPC2_noncoding.ids > all_concat_formatted_lncRNAs.gtf
echo "+++ DONE +++"

# Merge with ensembl annotation
echo "~~~~~ Tmerging with ensembl annotation ~~~~~"
cat all_concat_formatted_lncRNAs.gtf Danio_rerio.GRCz11.104.chr_formatted.gtf | ../../../Utils/sortgff - | ../../../Utils/tmerge --exonOverhangTolerance 8 --tmPrefix anch - | ../../../Utils/sortgff - > tmerged_with_ensemblRef.gtf
echo "+++ DONE +++"

# Build loci
echo "~~~~~ Building loci ~~~~~"
bedtools intersect -s -wao -a tmerged_with_ensemblRef.gtf -b tmerged_with_ensemblRef.gtf | ../../../Utils/buildLoci.pl - | ../../../Utils/sortgff - > tmerged_with_ensemblRef_loci.gtf
echo "+++ DONE +++"

# Merge to reference
echo "~~~~~ Merging to Ensembl reference ~~~~~"
../../../Utils/mergeToRef_danio.pl Danio_rerio.GRCz11.104.chr_formatted.gtf tmerged_with_ensemblRef_loci.gtf | ../../../Utils/sortgff - | gzip > ../output/mergedToEnsemblRef.gtf.gz
echo "+++ DONE +++"

# Report completion
echo "######## COMPLETED ########"
