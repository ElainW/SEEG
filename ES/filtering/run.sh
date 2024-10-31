#!/bin/bash
module load gcc/6.2.0 python/3.7.4
TOOLS_DIR=/home/yh174/tools
export PATH="$TOOLS_DIR/:$PATH"
BARCODE_LIST=("0863_Ti-G" "0859_Ti-A" "0859_A_" "0863_K" "0864_F" "0861_N_" "0868_R" "0871_J" "0500_B_" "0873_H")
INDIR=/n/groups/walsh/indData/elain/DeepWES4_7/MH
mkdir -p $INDIR/filtered_MH
printf "" > $INDIR/filtered_MH/raw.MH.tsv
for BARCODE_ID in ${BARCODE_LIST[@]}; do
	awk -v ID=${BARCODE_ID} '{if(($3==$7||$3==$9)&&$11~"N/A"&&$11~"1.0"&&$21<-1.3){print $0"\t"ID}}' $INDIR/$BARCODE_ID/final.passed.tsv >> $INDIR/filtered_MH/raw.MH.tsv
done
awk '{OFS="\t";if($3==$7){alt=$9;ref_num=$8;alt_num=$10}if($3==$9){alt=$7;ref_num=$10;alt_num=$8}print $1,$2,$3,alt,ref_num,alt_num,$25}' $INDIR/filtered_MH/raw.MH.tsv > $INDIR/filtered_MH/raw.complete.MH.tsv
awk -F"\t" '$6/($5+$6)<0.3' $INDIR/filtered_MH/raw.complete.MH.tsv > $INDIR/filtered_MH/filtered.complete.MH.tsv
sed -i 's/^/chr/' $INDIR/filtered_MH/filtered.complete.MH.tsv

# find overlaps between WES and panel seq
panel_MH=/n/groups/walsh/indData/elain/panel_seq_output/merged_vcf/MH.normalize.snpeff.clinvar.hgmd.epilepsygeneset.vcf
python3 get_panel_sample_vaf.py $panel_MH panel_sample_vaf.tsv
myjoin -m -F1,2,3,4 panel_sample_vaf.tsv -f1,2,3,4 <(awk -F"\t" '{OFS="\t"; print $0,$6/($5+$6)}' $INDIR/filtered_MH/filtered.complete.MH.tsv) | cut --complement -f8-11 > overlap.tsv