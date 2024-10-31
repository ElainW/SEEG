#!/bin/bash
THREAD_NUM=12
BARCODE_ID=$1
FQ1=$2
FQ2=$3
OUTDIR=$4

bwa mem -t ${THREAD_NUM} -C -M -R '@RG\tID:${BARCODE_ID}\tSM:human\tPL:illumina' /home/yh174/reference/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta $FQ1 $FQ2 | samtools view -Sb - > $OUTDIR/${BARCODE_ID}.bam