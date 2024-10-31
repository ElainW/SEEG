#!/bin/bash

INDIR=$1
PREFIX=$2
OUTDIR=$1
INTERVAL=$3

java -jar /n/groups/walsh/indData/Sattar/GATK/GenomeAnalysisTK-3.8-1-0/GenomeAnalysisTK.jar \
     -T RealignerTargetCreator \
     -R /home/yh174/reference/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta \
     -L $INTERVAL \
     -I $INDIR/$PREFIX.bam \
     -known /n/groups/walsh/indData/elain/databases/Homo_sapiens_assembly19.known_indels.vcf \
     -known /n/groups/walsh/indData/elain/databases/Mills_and_1000G_gold_standard.indels.hg19.sites.nochr.vcf \
     -o $OUTDIR/$PREFIX.realigner.intervals \
     --num_threads 4
