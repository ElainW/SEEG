#!/bin/bash
# same thing as run_two_step.sh but now using subsampled tissue samples for the sample-based filtering
# with different output directories
module load gcc/6.2.0 python/3.7.4 bcftools/1.13
#TOOLS_DIR=/home/yh174/tools
#export PATH="$TOOLS_DIR/:$PATH"
BARCODE_LIST=("subsampled_0863_Ti-G" "subsampled_0859_Ti-A" "0859_A_" "0863_K" "0864_F" "0861_N_" "0868_R" "0871_J" "0500_B_" "0873_H")
INDIR=/n/groups/walsh/indData/elain/DeepWES4_7/MH_2step_out
OUTDIR=$INDIR/filtered_MH_Ti_subsampled
mkdir -p $OUTDIR
printf "" > $OUTDIR/raw.MH.tsv
for BARCODE_ID in ${BARCODE_LIST[@]}; do
	awk -v ID=${BARCODE_ID} '{if(($3==$7||$3==$9)&&$11~"N/A"&&$11~"1.0"&&$21<-1.3){print $0"\t"ID}}' $INDIR/$BARCODE_ID/final.passed.tsv >> $OUTDIR/raw.MH.tsv
done
awk '{OFS="\t";if($3==$7){alt=$9;ref_num=$8;alt_num=$10}if($3==$9){alt=$7;ref_num=$10;alt_num=$8}print $1,$2,$3,alt,ref_num,alt_num,$25}' $OUTDIR/raw.MH.tsv > $OUTDIR/raw.complete.MH.tsv
awk -F"\t" '$6/($5+$6)<0.3' $OUTDIR/raw.complete.MH.tsv > $OUTDIR/filtered.complete.MH.tsv
sed -i 's/^/chr/' $OUTDIR/filtered.complete.MH.tsv

# get separate vcf for each sample
mkdir -p $OUTDIR/tmp
python3 MH_tsv_to_vcf_Ti_subsampled.py $OUTDIR/filtered.complete.MH.tsv $OUTDIR/tmp/
for BARCODE_ID in ${BARCODE_LIST[@]}; do
	bgzip $OUTDIR/tmp/$BARCODE_ID.vcf
	bcftools index $OUTDIR/tmp/$BARCODE_ID.vcf.gz
done
cd $OUTDIR
bcftools merge -Ov -o two_step_MH.vcf tmp/subsampled_0863_Ti-G.vcf.gz tmp/subsampled_0859_Ti-A.vcf.gz tmp/0859_A_.vcf.gz tmp/0863_K.vcf.gz tmp/0864_F.vcf.gz tmp/0861_N_.vcf.gz tmp/0868_R.vcf.gz tmp/0871_J.vcf.gz tmp/0500_B_.vcf.gz tmp/0873_H.vcf.gz