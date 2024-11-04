#!/bin/bash
module load gcc/6.2.0 bcftools/1.13

DIR=panel_seq_output
MH_DIR=$DIR/MosaicHunter
Pisces_DIR=$DIR/Pisces
OUTDIR=$DIR/merged_vcf
INPUT_DIR=../panel_seq_input

mkdir -p gen_scripts

printf "bcftools merge -Ov -o $OUTDIR/MH.vcf " > $SCRIPT_DIR/gen_scripts/gen_MH_vcf.sh
printf "bcftools merge -Ov -o $OUTDIR/Pisces.vcf " > $SCRIPT_DIR/gen_scripts/gen_Pisces_vcf.sh
cat $INPUT_DIR/barcode_id.txt | while read f; do printf "$ROOT/panel_seq_output/MosaicHunter/$f.MH.final.vcf.gz " >> $SCRIPT_DIR/gen_scripts/gen_MH_vcf.sh; printf "$ROOT/panel_seq_output/Pisces/$f.P.final.vcf.gz " >> $SCRIPT_DIR/gen_scripts/gen_Pisces_vcf.sh; done
bash ../gen_scripts/gen_MH_vcf.sh
bash ../gen_scripts/gen_Pisces_vcf.sh
