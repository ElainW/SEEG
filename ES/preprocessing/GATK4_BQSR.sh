#!/bin/bash
INDIR=$1
PREFIX=$2
INTERVAL=$3
OUTDIR=$4

export PATH="/n/groups/walsh/indData/Sattar/GATK/gatk-4.1.9.0/:$PATH"
gatk ApplyBQSR \
      -R /home/yh174/reference/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta \
      -I $INDIR/$PREFIX.indel_realigned.bam \
      -O $OUTDIR/$PREFIX.bam \
      -L $INTERVAL \
      --interval-padding 100 \
      -bqsr $INDIR/$PREFIX.indel_realigned.recalibration.report \
      --static-quantized-quals 10 --static-quantized-quals 20 --static-quantized-quals 30 \
      --add-output-sam-program-record \
      --create-output-bam-md5 \
      --use-original-qualities \
      --tmp-dir $OUTDIR
