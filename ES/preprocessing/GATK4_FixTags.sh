#! /bin/bash
export PATH="/n/groups/walsh/indData/Sattar/GATK/gatk-4.1.9.0/:$PATH"

INDIR=$1
PREFIX=$2
OUTDIR=$3
gatk SetNmMdAndUqTags \
      --INPUT $INDIR/$PREFIX.bam \
      --OUTPUT $OUTDIR/$PREFIX.bam \
      --CREATE_INDEX true \
      --CREATE_MD5_FILE false \
      --REFERENCE_SEQUENCE /home/yh174/reference/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta \
      --TMP_DIR $OUTDIR
