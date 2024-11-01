#!/bin/bash

REFERENCE_DIR=...
TOOLS_DIR=../tools
TEMP_DIR=...
ROOT=...
SCRIPT_DIR=../panel_seq/variant_calling
INPUT_DIR=../panel_seq/panel_seq_input
#FASTQ_DIR=$ROOT/30-699833257/00_fastq
export PATH="$SCRIPT_DIR/:$TOOLS_DIR/:$PATH"

MAP ()
{
	BARCODE_ID=$1
	THREAD_NUM=$2
	OUTDIR=$3
	SEQ_ID=$4
	FASTQ_DIR=$ROOT/${SEQ_ID}/00_fastq
	
	mkdir -p $OUTDIR
	bwa mem -t ${THREAD_NUM} -C -M -R "@RG\tID:${BARCODE_ID}\tSM:human\tPL:illumina" ${REFERENCE_DIR}/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta <(zcat $FASTQ_DIR/${BARCODE_ID}_R1_001.fastq.gz | cut -f1 -d " ") <(zcat $FASTQ_DIR/${BARCODE_ID}_R2_001.fastq.gz | cut -f1 -d " ") | samtools view -Sb - > $OUTDIR/${BARCODE_ID}.bam
	run_picard.sh SortSam INPUT=$OUTDIR/${BARCODE_ID}.bam OUTPUT=$OUTDIR/${BARCODE_ID}.sorted.bam SORT_ORDER=coordinate VALIDATION_STRINGENCY=SILENT
	samtools index $OUTDIR/${BARCODE_ID}.sorted.bam
	run_gatk_3.6.sh -T RealignerTargetCreator -nt ${THREAD_NUM} -R ${REFERENCE_DIR}/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta -I $OUTDIR/${BARCODE_ID}.sorted.bam -o $OUTDIR/${BARCODE_ID}.realigned.intervals
	run_gatk_3.6.sh -T IndelRealigner -R ${REFERENCE_DIR}/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta -I $OUTDIR/${BARCODE_ID}.sorted.bam -targetIntervals $OUTDIR/${BARCODE_ID}.realigned.intervals -o $OUTDIR/${BARCODE_ID}.final.bam
	samtools index $OUTDIR/${BARCODE_ID}.final.bam
	rm $OUTDIR/${BARCODE_ID}.bam $OUTDIR/${BARCODE_ID}.sorted.bam $OUTDIR/${BARCODE_ID}.sorted.bam.bai $OUTDIR/${BARCODE_ID}.realigned.intervals
}
#mkdir -p MosaicHunter
#samtools mpileup -f ${REFERENCE_DIR}/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta -s -B -Q 0 -q 0 bam/${BARCODE_ID}.final.bam -l <(awk '{OFS="\t"; print $3,$4-1,$4}' ${PROJECT_HEADER}.sample.txt | uniq) | java -classpath ${TOOLS_DIR} PileupFilter --minbasequal=0 --minmapqual=0 --asciibase=33 --filtered=1 | gzip > MosaicHunter/${BARCODE_ID}.pileup.gz
#zcat MosaicHunter/${BARCODE_ID}.pileup.gz | awk '{OFS="\t"; print $1,$2-1,$2,$3,$12,$15,$16.$17,$18.$19,$20.$21}' | sed -e 's/|/~/g' > MosaicHunter/${BARCODE_ID}.temp
#Rscript ${TOOLS_DIR}/mosaicHunterR.R MosaicHunter/${BARCODE_ID}.temp MosaicHunter/${BARCODE_ID}.MH.tsv

MAP $1 $2 $3 $4