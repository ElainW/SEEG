#!/bin/bash
# QC for average depth within the targeted intervals for the raw bam file and the final cleaned bam file (after BQSR and after MH clean)
module load gcc/6.2.0 samtools/0.1.19 bedtools/2.27.1 python/3.7.4
source ~/yw222PythonFolder/python_bam/bin/activate

INPUT_DIR=$ROOT/DeepWES4_7/final
INTERVAL=S33266340_Regions.nochr.bed
BARCODE_LIST=("0863_Ti-G" "0859_Ti-A" "0859_A_" "0863_K" "0873_H" "0864_F" "0861_N_" "0868_R" "0871_J" "0500_B_" "0873_H")

for BARCODE_ID in ${BARCODE_LIST[@]}; do
	sbatch -J $BARCODE_ID -N 1 -c 1 --mem=3G -t 0-3:00 -p short -o logs/${BARCODE_ID}_coverage.log --mail-user=... --mail-type=FAIL,END calc_avg_cov.sh $INPUT_DIR $BARCODE_ID $INTERVAL
done
