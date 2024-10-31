#!/bin/bash

export PATH="/n/groups/walsh/indData/Sattar/GATK/gatk-4.1.9.0/:$PATH"

INDIR=$1
PREFIX=$2
OUTDIR=$3
gatk SortSam \
      --INPUT $INDIR/$PREFIX.bam \
      --OUTPUT $INDIR/$PREFIX.sorted.bam \
      --SORT_ORDER "coordinate" \
      --CREATE_INDEX false \
      --CREATE_MD5_FILE false \
      --TMP_DIR $OUTDIR \
