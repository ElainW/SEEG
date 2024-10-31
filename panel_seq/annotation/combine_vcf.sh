#!/bin/bash
module load gcc/6.2.0 bcftools/1.13

DIR=/n/groups/walsh/indData/elain/panel_seq_output
MH_DIR=$DIR/MosaicHunter
Pisces_DIR=$DIR/Pisces
OUTDIR=$DIR/merged_vcf
ROOT=/n/groups/walsh/indData/elain
SCRIPT_DIR=$ROOT/scripts
#INPUT_DIR=/n/data1/bch/genetics/lee/August/AD_clonal/cancer_panel
INPUT_DIR=$SCRIPT_DIR/panel_seq_input

mkdir -p gen_scripts

# printf "bcftools merge -Ov -o $OUTDIR/MH.vcf " > $SCRIPT_DIR/gen_scripts/gen_MH_vcf.sh
# printf "bcftools merge -Ov -o $OUTDIR/Pisces.vcf " > $SCRIPT_DIR/gen_scripts/gen_Pisces_vcf.sh
# cat $INPUT_DIR/barcode_id.txt | while read f; do printf "$ROOT/panel_seq_output/MosaicHunter/$f.MH.final.vcf.gz " >> $SCRIPT_DIR/gen_scripts/gen_MH_vcf.sh; printf "$ROOT/panel_seq_output/Pisces/$f.P.final.vcf.gz " >> $SCRIPT_DIR/gen_scripts/gen_Pisces_vcf.sh; done
# bash $SCRIPT_DIR/gen_scripts/gen_MH_vcf.sh
# bash $SCRIPT_DIR/gen_scripts/gen_Pisces_vcf.sh

# for XI=2
printf "bcftools merge -Ov -o $OUTDIR/MH_XI2.vcf " > $SCRIPT_DIR/gen_scripts/gen_MH_vcf_XI2.sh
printf "bcftools merge -Ov -o $OUTDIR/Pisces_XI2.vcf " > $SCRIPT_DIR/gen_scripts/gen_Pisces_vcf_XI2.sh
cat $INPUT_DIR/barcode_id.txt | while read f; do printf "$ROOT/panel_seq_output/MosaicHunter_XI2/$f.MH.final.vcf.gz " >> $SCRIPT_DIR/gen_scripts/gen_MH_vcf_XI2.sh; printf "$ROOT/panel_seq_output/Pisces_XI2/$f.P.final.vcf.gz " >> $SCRIPT_DIR/gen_scripts/gen_Pisces_vcf_XI2.sh; done
bash $SCRIPT_DIR/gen_scripts/gen_MH_vcf_XI2.sh
bash $SCRIPT_DIR/gen_scripts/gen_Pisces_vcf_XI2.sh
