#!/bin/bash
INPUT_DIR=$1
BARCODE_ID=$2
INTERVAL=$3
bedtools genomecov -ibam $INPUT_DIR/${BARCODE_ID}.bam -bg | intersectBed -sorted -a stdin -b $INTERVAL | awk -F"\t" '{OFS="\t";print $3-$2,$4}' | awk -F"\t" '{a[$2]+=$1} END{for (i in a) print i,a[i]}' | sort -V -k1,1n > $INPUT_DIR/${BARCODE_ID}.counts
python3 /n/data1/bch/genetics/lee/elain/TLE/scripts/ras_panel/variantcalling/calc_avg_cov.py -i $INPUT_DIR/${BARCODE_ID}.counts -o $INPUT_DIR/${BARCODE_ID}.coverage
bedtools genomecov -ibam $INPUT_DIR/${BARCODE_ID}.final.bam -bg | intersectBed -sorted -a stdin -b $INTERVAL | awk -F"\t" '{OFS="\t";print $3-$2,$4}' | awk -F"\t" '{a[$2]+=$1} END{for (i in a) print i,a[i]}' | sort -V -k1,1n > $INPUT_DIR/${BARCODE_ID}.final.counts
python3 /n/data1/bch/genetics/lee/elain/TLE/scripts/ras_panel/variantcalling/calc_avg_cov.py -i $INPUT_DIR/${BARCODE_ID}.final.counts -o $INPUT_DIR/${BARCODE_ID}_final.coverage