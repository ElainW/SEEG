#!/bin/bash

module load gcc/6.2.0 samtools/0.1.19 bwa/0.7.15 bedtools/2.27.1 java/jdk-1.8u112 R/4.0.1
REFERENCE_DIR=...
TOOLS_DIR=../../tools
TEMP_DIR=...
ROOT=...
SCRIPT_DIR=$ROOT/scripts
INPUT_DIR=../panel_seq_input
FASTQ_DIR=...
OUTPUT_DIR=...
export PATH="$TOOLS_DIR/:$SCRIPT_DIR/:$TOOLS_DIR/Pisces-5.3/:$PATH"
mkdir -p $OUTPUT_DIR
cd $OUTPUT_DIR

PREPARATION () # update all input
{
	awk '$1~"chr"' $INPUT_DIR/FCDHME-122021-2_1_Covered.bed | sed -e 's/^chr//g' > $INPUT_DIR/FCDHME-122021-2_1_Covered.b37.bed
	
	dotnet ~/CreateGenomeSizeFile_5.2.7.47/CreateGenomeSizeFile.dll -g ${REFERENCE_DIR}/human_v37_contig_hg19_hs37d5/ -s "Homo Sapiens (hs37d5)"
}


PREPARATION
while read LINE; do
	sbatch -J $LINE -o ${LINE}_fixXI.log --mem=8G -t 0-12:00 -N 1 -c 4 -p short --mail-user=... --mail-type=FAIL,END --wrap="bash identification.sh $LINE 4"
done < $INPUT_DIR/barcode_id.txt
