#!/bin/bash

# get rid of the chr's
INFILE=/n/data1/bch/genetics/lee/reference/hg19/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf
OUTFILE=/n/groups/walsh/indData/elain/databases/Mills_and_1000G_gold_standard.indels.hg19.sites.nochr.vcf
sed 's/^chr//' $INFILE | sed 's/^##contig=<ID=chr/##contig=<ID=/' > $OUTFILE