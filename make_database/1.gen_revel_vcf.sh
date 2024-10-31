#!/bin/bash
#SBATCH -J gen_revel_vcf
#SBATCH -N 1
#SBATCH -c 1
#SBATCH -o gen_revel_vcf.log
#SBATCH --mem 1G
#SBATCH -t 0-00:30
#SBATCH -p short
#SBATCH --mail-user=yilanwang@g.harvard.edu
#SBATCH --mail-type=FAIL,END

cd /n/groups/walsh/indData/Sattar/WES/KMTS/variant_prioritization/databases
OUTDIR=/n/groups/walsh/indData/elain/databases
printf "##INFO=<ID=RESC,Number=1,Type=Float,Description=\"Revel score ranges from 0-1, the higher the score, the higher the probability of pathogenicity\">\n" > $OUTDIR/revel_hg19.vcf
printf "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n" >> $OUTDIR/revel_hg19.vcf
tail -n +2 revel_with_transcript_ids | awk -F"," '{OFS="\t"; print "chr"$1,$2,".",$4,$5,".","PASS","RESC="$8}' | awk -F'\t' '$2!="."' | sort -k1,1 -k2,2n >> $OUTDIR/revel_hg19.vcf
bgzip -cf $OUTDIR/revel_hg19.vcf > $OUTDIR/revel_hg19.vcf.gz
tabix $OUTDIR/revel_hg19.vcf.gz