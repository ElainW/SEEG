#!/bin/bash
# makes the CLINVAR bed file to annotate non-SNVs --> 2023/05/08 include all variants --> 2024/03/18 update clinvar database
module load gcc/6.2.0 python/3.7.4

# this is for older clinvar, last modified 2023/05/08
# DIR=/n/groups/walsh/indData/Sattar/GATK/reference/
# # filter out snvs --> no! we should use all the variants
# # python3 filter_out_snv.py $DIR/clinvar.vcf $DIR/clinvar_no_snv.vcf
# make it into a bed file with only CLINSIG=Pathogenic, Likely_pathogenic, Pathogenic/Likely_pathogenic
# zgrep -v "^##" $DIR/clinvar.vcf.gz | cut -f1,2,8 > $DIR/clinvar.tmp
# python3 make_clinvar_bed.py $DIR/clinvar.tmp $DIR/clinvar.bed

# 2024/03/18 using updated clinvar from 20240107
DIR=/n/groups/walsh/indData/Sattar/WES/KMTS/variant_prioritization/databases/ClinVar/
# make it into a bed file with only CLINSIG=Pathogenic, Likely_pathogenic, Pathogenic/Likely_pathogenic
zgrep -v "^##" $DIR/clinvar_20240107.vcf.gz | cut -f1,2,8 > $DIR/clinvar_20240107.tmp
python3 make_clinvar_bed.py $DIR/clinvar_20240107.tmp $DIR/clinvar_20240107.bed
rm $DIR/clinvar_20240107.tmp