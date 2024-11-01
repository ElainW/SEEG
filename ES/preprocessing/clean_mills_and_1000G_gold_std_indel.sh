#!/bin/bash

# get rid of the chr's
INFILE=$REFERENCE_DIR/hg19/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf
OUTFILE=../../database/Mills_and_1000G_gold_standard.indels.hg19.sites.nochr.vcf
sed 's/^chr//' $INFILE | sed 's/^##contig=<ID=chr/##contig=<ID=/' > $OUTFILE