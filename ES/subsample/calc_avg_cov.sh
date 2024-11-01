#!/bin/bash
module load gcc/6.2.0 bedtools/2.27.1 python/3.7.4

PREFIX=$1
BED_INT=$2
if [[ $BED_INT == "" ]]; then
	awk -F"\t" '{OFS="\t";print $3-$2,$4}' ${PREFIX}.per-base.bed | awk -F"\t" '{a[$2]+=$1} END{for (i in a) print i,a[i]}' | sort -V -k1,1n > $PREFIX.counts
else
	intersectBed -sorted -a ${PREFIX}.per-base.bed -b $BED_INT | awk -F"\t" '{OFS="\t";print $3-$2,$4}' | awk -F"\t" '{a[$2]+=$1} END{for (i in a) print i,a[i]}' | sort -V -k1,1n > $PREFIX.counts
fi
python3 calc_avg_cov.py -i $PREFIX.counts
