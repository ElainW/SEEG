#!/bin/bash
INDIR=$1
PREFIX=$2
INTERVAL=$3
TMP_DIR=$4

export PATH="/n/groups/walsh/indData/Sattar/GATK/gatk-4.1.9.0/:$PATH"

gatk BaseRecalibrator \
      -R /home/yh174/reference/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta \
      -I $INDIR/$PREFIX.indel_realigned.bam \
      --use-original-qualities \
      -O $INDIR/$PREFIX.indel_realigned.recalibration.report \
      --known-sites /n/groups/walsh/indData/elain/databases/Homo_sapiens_assembly19.dbsnp138.vcf \
      --known-sites /n/groups/walsh/indData/elain/databases/Mills_and_1000G_gold_standard.indels.hg19.sites.nochr.vcf \
      -L $INTERVAL \
      --interval-padding 100 \
      --tmp-dir $TMP_DIR
