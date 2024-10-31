#!/bin/bash
REFERENCE_DIR=/home/yh174/reference
TOOLS_DIR=/home/yh174/tools
TEMP_DIR=/home/yw222/temp
ROOT=/n/groups/walsh/indData/elain
SCRIPT_DIR=$ROOT/scripts/variant_calling
#INPUT_DIR=/n/data1/bch/genetics/lee/August/AD_clonal/cancer_panel
INPUT_DIR=$ROOT/scripts/panel_seq_input
FASTQ_DIR=$ROOT/TargetedPanelwithWes
OUTPUT_DIR=$ROOT/panel_seq_output
export PATH="$TOOLS_DIR/:$SCRIPT_DIR/:$TOOLS_DIR/Pisces-5.3/:$PATH"
cd $OUTPUT_DIR

IDENTIFICATION ()
{
	BARCODE_ID=$1
	THREAD_NUM=$2
	MIN_XI=1 # using 1 instead, otherwise the average coverage is <100x (too low for variant calling)
	
	mkdir -p trimmedFastq
	$SCRIPT_DIR/run_agent_trimmer.sh -fq1 $FASTQ_DIR/${BARCODE_ID}_1.fastq.gz -fq2 $FASTQ_DIR/${BARCODE_ID}_2.fastq.gz -v2 -out_loc trimmedFastq/
	ls trimmedFastq/${BARCODE_ID}_1.*.fastq.gz | head -n 1 | while read f; do mv $f trimmedFastq/${BARCODE_ID}_1.fastq.gz; done
	ls trimmedFastq/${BARCODE_ID}_2.*.fastq.gz | head -n 1 | while read f; do mv $f trimmedFastq/${BARCODE_ID}_2.fastq.gz; done
	ls trimmedFastq/${BARCODE_ID}_N.*.txt.gz | head -n 1 | while read f; do mv $f trimmedFastq/${BARCODE_ID}_N.txt.gz; done
	
	mkdir -p bam
	bwa mem -t ${THREAD_NUM} -C -M -R '@RG\tID:${BARCODE_ID}\tSM:human\tPL:illumina' ${REFERENCE_DIR}/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta trimmedFastq/${BARCODE_ID}_1.fastq.gz trimmedFastq/${BARCODE_ID}_2.fastq.gz | samtools view -Sb - > bam/${BARCODE_ID}.bam
	$SCRIPT_DIR/run_picard.sh SortSam INPUT=bam/${BARCODE_ID}.bam OUTPUT=bam/${BARCODE_ID}.sorted.bam SORT_ORDER=coordinate VALIDATION_STRINGENCY=SILENT
	samtools index bam/${BARCODE_ID}.sorted.bam
	#$SCRIPT_DIR/run_agent_locatit.sh -U -S -v2Only -d 1 -m 1 -q 20 -Q 10 -l $INPUT_DIR/FCDHME-122021-2_1_Covered.b37.bed -o bam/${BARCODE_ID}.masked.bam -X ${TEMP_DIR}/${BARCODE_ID}/ bam/${BARCODE_ID}.bam
	#$SCRIPT_DIR/run_picard.sh SortSam INPUT=bam/${BARCODE_ID}.masked.bam OUTPUT=bam/${BARCODE_ID}.masked.sorted.bam SORT_ORDER=coordinate VALIDATION_STRINGENCY=SILENT
	#samtools index bam/${BARCODE_ID}.masked.sorted.bam
	#$SCRIPT_DIR/run_gatk_3.6.sh -T RealignerTargetCreator -nt ${THREAD_NUM} -R ${REFERENCE_DIR}/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta -I bam/${BARCODE_ID}.masked.sorted.bam -o bam/${BARCODE_ID}.masked.realigned.intervals
	#$SCRIPT_DIR/run_gatk_3.6.sh -T IndelRealigner -R ${REFERENCE_DIR}/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta -I bam/${BARCODE_ID}.masked.sorted.bam -targetIntervals bam/${BARCODE_ID}.masked.realigned.intervals -o bam/${BARCODE_ID}.masked.realigned.bam
	# try out a different UMI collapsing (single consensus, only remove PCR duplicates)
	if [ ! -f bam/${BARCODE_ID}.single.masked.realigned.bam ]; then
		$SCRIPT_DIR/run_agent_locatit.sh -U -S -R -d 1 -m 1 -q 20 -Q 10 -l $INPUT_DIR/FCDHME-122021-2_1_Covered.b37.strand.bed -o bam/${BARCODE_ID}.single.masked.bam -X ${TEMP_DIR}/${BARCODE_ID}/ bam/${BARCODE_ID}.bam trimmedFastq/${BARCODE_ID}_N.txt.gz
		$SCRIPT_DIR/run_picard.sh SortSam INPUT=bam/${BARCODE_ID}.single.masked.bam OUTPUT=bam/${BARCODE_ID}.single.masked.sorted.bam SORT_ORDER=coordinate VALIDATION_STRINGENCY=SILENT
		samtools index bam/${BARCODE_ID}.single.masked.sorted.bam
		$SCRIPT_DIR/run_gatk_3.6.sh -T RealignerTargetCreator -nt ${THREAD_NUM} -R ${REFERENCE_DIR}/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta -I bam/${BARCODE_ID}.single.masked.sorted.bam -o bam/${BARCODE_ID}.single.masked.realigned.intervals
		$SCRIPT_DIR/run_gatk_3.6.sh -T IndelRealigner -R ${REFERENCE_DIR}/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta -I bam/${BARCODE_ID}.single.masked.sorted.bam -targetIntervals bam/${BARCODE_ID}.single.masked.realigned.intervals -o bam/${BARCODE_ID}.single.masked.realigned.bam
	fi
	
	mkdir -p finalBam
	samtools view -h bam/${BARCODE_ID}.single.masked.realigned.bam -F 3840 | perl -ne 'print if (/^@/||(/XI:i:(\d+)/&&$1>=1))' | trimBamByBlock.pl --trim_end=5 --trim_intron=0 --trim_indel=0 | samtools view -Sb - > finalBam/${BARCODE_ID}.final.bam
	samtools index finalBam/${BARCODE_ID}.final.bam
	coverageBed -abam finalBam/${BARCODE_ID}.final.bam -b $INPUT_DIR/FCDHME-122021-2_1_Covered.b37.bed -hist > finalBam/${BARCODE_ID}.final.coverageBed
	
	mkdir -p NaiveCaller	
	java -Xmx64g -jar $TOOLS_DIR/NaiveCaller/NaiveCaller.jar -r ${REFERENCE_DIR}/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta -b finalBam/${BARCODE_ID}.final.bam -e $INPUT_DIR/FCDHME-122021-2_1_Covered.b37.bed -P 0 -q 20 -Q 40 -o NaiveCaller/${BARCODE_ID}.NC.tsv
	
	mkdir -p MosaicHunter # wanna make sure that variants are called on more than 1 PE read
	grep -v "^Chrom" NaiveCaller/${BARCODE_ID}.NC.tsv | awk '{sum=0;if($6>0){sum++}if($7>0){sum++}if($8>0){sum++}if($9>0){sum++}if(sum>=2){OFS="\t";print $1,$2-1,$2}}' > MosaicHunter/${BARCODE_ID}.bed
	samtools mpileup -f ${REFERENCE_DIR}/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta -s -B -Q 0 -q 0 finalBam/${BARCODE_ID}.final.bam -l MosaicHunter/${BARCODE_ID}.bed | java -classpath ${TOOLS_DIR} PileupFilter --minbasequal=20 --minmapqual=40 --asciibase=33 --filtered=1 | gzip > MosaicHunter/${BARCODE_ID}.pileup.gz
	zcat MosaicHunter/${BARCODE_ID}.pileup.gz | awk '{OFS="\t"; print $1,$2-1,$2,$3,$12,$15,$16.$17,$18.$19,$20.$21}' | sed -e 's/|/~/g' > MosaicHunter/${BARCODE_ID}.temp
	Rscript $TOOLS_DIR/mosaicHunterR.R MosaicHunter/${BARCODE_ID}.temp MosaicHunter/${BARCODE_ID}.MH.tsv
	
	mkdir -p Pisces
	Pisces -t ${THREAD_NUM} -B finalBam/${BARCODE_ID}.final.bam -g ${REFERENCE_DIR}/human_v37_contig_hg19_hs37d5 -gVCF false -i $INPUT_DIR/FCDHME-122021-2_1_Covered.b37.bed -OutFolder Pisces -MinVF 0.0005 -SSFilter false -MinBQ 20 -MaxVQ 100 -MinVQ 0 -VQFilter 20 -CallMNVs False -RMxNFilter 5,9,0.35 -MinDepth 5 -threadbychr true
	
	rm -f bam/${BARCODE_ID}.bam bam/${BARCODE_ID}.masked.bam bam/${BARCODE_ID}.masked.bai bam/${BARCODE_ID}.masked.sorted.bam bam/${BARCODE_ID}.masked.sorted.bam.bai
	rm -f MosaicHunter/${BARCODE_ID}.bed MosaicHunter/${BARCODE_ID}.pileup.gz MosaicHunter/${BARCODE_ID}.temp
}

IDENTIFICATION $1 $2
