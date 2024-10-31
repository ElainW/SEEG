#!/bin/bash

INDIR=$1
PREFIX=$2
OUTDIR=$3

PICARD_DIR=/home/yh174/tools/picard-1.138/bin

java -XX:+UseSerialGC -Xmx40G -jar ${PICARD_DIR}/picard.jar MarkDuplicates \
REMOVE_DUPLICATES=True \
ASSUME_SORTED=False \
INPUT=$INDIR/$PREFIX.sorted.bam \
OUTPUT=$OUTDIR/$PREFIX.bam \
METRICS_FILE=$OUTDIR/${PREFIX}_marked_dup_metrics.txt

samtools index $OUTDIR/$PREFIX.bam
