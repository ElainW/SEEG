#!/bin/bash

# softwares version
#samtools: 0.1.19
#bwa: 0.7.15-r1140
#agent: 2.0.2
#bedtools: 2.23.0
#picard: 1.138
#gatk: 3.6
#annovar: 2015Mar22

module load gcc/6.2.0 samtools/0.1.19 bwa/0.7.15 bedtools/2.27.1 java/jdk-1.8u112 R/4.0.1
REFERENCE_DIR=/home/yh174/reference
TOOLS_DIR=/home/yh174/tools
TEMP_DIR=/home/yw222/temp
ROOT=/n/groups/walsh/indData/elain
SCRIPT_DIR=$ROOT/scripts
INPUT_DIR=$SCRIPT_DIR/panel_seq_input
FASTQ_DIR=$ROOT/TargetedPanelwithWes
OUTPUT_DIR=$ROOT/panel_seq_output
export PATH="$TOOLS_DIR/:$SCRIPT_DIR/:$TOOLS_DIR/Pisces-5.3/:$PATH"
mkdir -p $OUTPUT_DIR
cd $OUTPUT_DIR

PREPARATION () # update all input
{
	awk '$1~"chr"' $INPUT_DIR/FCDHME-122021-2_1_Covered.bed | sed -e 's/^chr//g' > $INPUT_DIR/FCDHME-122021-2_1_Covered.b37.bed
	
	# what is this? seems very different from my input
	#myjoin <(cut -f1 AD_panel.sample.list) -f44 <(awk -F "\t" '$45==""' AD_cancer_sureselect_orientation_v3.txt) | awk -F "\t" '{if($1=="="||$1=="+"){OFS="\t"; print $2,$33,$36,$26,$30,$37,$39,$24}}' > AD_panel.sample.clinical.tsv
	# this file designates which input is case, which input is control (in the column of clinical)
	
	/home/jk438/dotnet/dotnet ~/CreateGenomeSizeFile_5.2.7.47/CreateGenomeSizeFile.dll -g ${REFERENCE_DIR}/human_v37_contig_hg19_hs37d5/ -s "Homo Sapiens (hs37d5)"
}

IDENTIFICATION ()
{
	BARCODE_ID=$1
	THREAD_NUM=$2
	MIN_XI=2
	
	mkdir -p trimmedFastq
	run_agent_trimmer.sh -fq1 $FASTQ_DIR/${BARCODE_ID}_1.fastq.gz -fq2 $FASTQ_DIR/${BARCODE_ID}_2.fastq.gz -v2 -out_loc trimmedFastq/
	ls trimmedFastq/${BARCODE_ID}_1.*.fastq.gz | head -n 1 | while read f; do mv $f trimmedFastq/${BARCODE_ID}_1.fastq.gz; done
	ls trimmedFastq/${BARCODE_ID}_2.*.fastq.gz | head -n 1 | while read f; do mv $f trimmedFastq/${BARCODE_ID}_2.fastq.gz; done
	ls trimmedFastq/${BARCODE_ID}_N.*.txt.gz | head -n 1 | while read f; do mv $f trimmedFastq/${BARCODE_ID}_N.txt.gz; done
	
	mkdir -p bam
	bwa mem -t ${THREAD_NUM} -C -M -R '@RG\tID:${BARCODE_ID}\tSM:human\tPL:illumina' ${REFERENCE_DIR}/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta trimmedFastq/${BARCODE_ID}_R1.fastq.gz trimmedFastq/${BARCODE_ID}_R2.fastq.gz | samtools view -Sb - > bam/${BARCODE_ID}.bam
	run_agent_locatit.sh -U -S -v2Only -d 1 -m 1 -q 20 -Q 10 -l $INPUT_DIR/FCDHME-122021-2_1_Covered.b37.bed -o bam/${BARCODE_ID}.masked.bam -X ${TEMP_DIR}/${BARCODE_ID}/ bam/${BARCODE_ID}.bam
	run_picard.sh SortSam INPUT=bam/${BARCODE_ID}.masked.bam OUTPUT=bam/${BARCODE_ID}.masked.sorted.bam SORT_ORDER=coordinate VALIDATION_STRINGENCY=SILENT
	samtools index bam/${BARCODE_ID}.masked.sorted.bam
	run_gatk_3.6.sh -T RealignerTargetCreator -nt ${THREAD_NUM} -R ${REFERENCE_DIR}/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta -I bam/${BARCODE_ID}.masked.sorted.bam -o bam/${BARCODE_ID}.masked.realigned.intervals
	run_gatk_3.6.sh -T IndelRealigner -R ${REFERENCE_DIR}/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta -I bam/${BARCODE_ID}.masked.sorted.bam -targetIntervals bam/${BARCODE_ID}.masked.realigned.intervals -o bam/${BARCODE_ID}.masked.realigned.bam

	mkdir -p finalBam
	samtools view -h bam/${BARCODE_ID}.masked.realigned.bam -F 3840 | perl -ne 'print if (/^@/||(/XI:i:(\d+)/&&$1>=${MIN_XI}))' | trimBamByBlock.pl --trim_end=5 --trim_intron=0 --trim_indel=0 | samtools view -Sb - > finalBam/${BARCODE_ID}.final.bam
	samtools index finalBam/${BARCODE_ID}.final.bam
	coverageBed -abam finalBam/${BARCODE_ID}.final.bam -b $INPUT_DIR/FCDHME-122021-2_1_Covered.b37.bed -hist > finalBam/${BARCODE_ID}.final.coverageBed
	
	mkdir -p NaiveCaller	
	java -Xmx64g -jar NaiveCaller/NaiveCaller.jar -r ${REFERENCE_DIR}/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta -b finalBam/${BARCODE_ID}.final.bam -e $INPUT_DIR/FCDHME-122021-2_1_Covered.b37.bed -P 0 -q 20 -Q 40 -o NaiveCaller/${BARCODE_ID}.NC.tsv
	
	mkdir -p MosaicHunter
	grep -v "^Chrom" NaiveCaller/${BARCODE_ID}.NC.tsv | awk '{sum=0;if($6>0){sum++}if($7>0){sum++}if($8>0){sum++}if($9>0){sum++}if(sum>=2){OFS="\t";print $1,$2-1,$2}}' > MosaicHunter/${BARCODE_ID}.bed
	samtools mpileup -f ${REFERENCE_DIR}/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta -s -B -Q 0 -q 0 finalBam/${BARCODE_ID}.final.bam -l MosaicHunter/${BARCODE_ID}.bed | java -classpath ${TOOLS_DIR} PileupFilter --minbasequal=20 --minmapqual=40 --asciibase=33 --filtered=1 | gzip > MosaicHunter/${BARCODE_ID}.pileup.gz
	zcat MosaicHunter/${BARCODE_ID}.pileup.gz | awk '{OFS="\t"; print $1,$2-1,$2,$3,$12,$15,$16.$17,$18.$19,$20.$21}' | sed -e 's/|/~/g' > MosaicHunter/${BARCODE_ID}.temp
	Rscript mosaicHunterR.R MosaicHunter/${BARCODE_ID}.temp MosaicHunter/${BARCODE_ID}.MH.tsv
	
	mkdir -p Pisces
	Pisces -t ${THREAD_NUM} -B finalBam/${BARCODE_ID}.final.bam -g ${REFERENCE_DIR}/human_v37_contig_hg19_hs37d5 -gVCF false -i $INPUT_DIR/FCDHME-122021-2_1_Covered.b37.bed -OutFolder Pisces -MinVF 0.0005 -SSFilter false -MinBQ 20 -MaxVQ 100 -MinVQ 0 -VQFilter 20 -CallMNVs False -RMxNFilter 5,9,0.35 -MinDepth 5 -threadbychr true
	
	rm -f bam/${BARCODE_ID}.bam bam/${BARCODE_ID}.masked.bam bam/${BARCODE_ID}.masked.bai bam/${BARCODE_ID}.masked.sorted.bam bam/${BARCODE_ID}.masked.sorted.bam.bai
	rm -f MosaicHunter/${BARCODE_ID}.bed MosaicHunter/${BARCODE_ID}.pileup.gz MosaicHunter/${BARCODE_ID}.temp
}

SUMMARY ()
{
	grep "done" AD_panel.sample.list | cut -f1 | while read f; do echo $f; cat finalBam/$f.final.coverageBed | awk '$1=="all"' | awk '{sum+=$2*$5}END{print sum}'; cat finalBam/$f.final.coverageBed | awk '$1=="all"' | awk '{if($2>500){sum+=$5}}END{print sum}'; done | paste - - - > AD_panel.coverage.summary
	
	# need to update this!!!
	# file format: chr pos count_NCI count_MCI count_AD count_NA
	grep "done" AD_panel.sample.list | cut -f1 | while read f; do awk '$7>3&&$7/($6+$7+$8)<0.3&&10^$12>0.5' MosaicHunter/$f.MH.tsv | cut -f1,2 | while read f1 f2; do echo $f1; echo $f2; cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7==1' | cut -f1 | while read f3; do awk '$7>0' MosaicHunter/$f3.MH.tsv; done | awk -v chr=$f1 -v pos=$f2 '$1==chr&&$2==pos' | wc -l; cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7==2||$7==3' | cut -f1 | while read f3; do awk '$7>0' MosaicHunter/$f3.MH.tsv; done | awk -v chr=$f1 -v pos=$f2 '$1==chr&&$2==pos' | wc -l; cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7==4||$7==5' | cut -f1 | while read f3; do awk '$7>0' MosaicHunter/$f3.MH.tsv; done | awk -v chr=$f1 -v pos=$f2 '$1==chr&&$2==pos' | wc -l; cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7==""' | cut -f1 | while read f3; do awk '$7>0' MosaicHunter/$f3.MH.tsv; done | awk -v chr=$f1 -v pos=$f2 '$1==chr&&$2==pos' | wc -l; done | paste - - - - - - > MosaicHunter/$f.raw.check; done
	grep "done" AD_panel.sample.list | cut -f1 | while read f; do awk '$7>3&&$7/($6+$7+$8)<0.3&&10^$12>0.5' MosaicHunter/$f.MH.tsv | cut -f1,2 | while read f1 f2; do echo $f1; echo $f2; cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7==1' | cut -f1 | while read f3; do awk '$7/($6+$7+$8)<0.3&&10^$12>0.5' MosaicHunter/$f3.MH.tsv; done | awk -v chr=$f1 -v pos=$f2 '$1==chr&&$2==pos' | wc -l; cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7==2||$7==3' | cut -f1 | while read f3; do awk '$7/($6+$7+$8)<0.3&&10^$12>0.5' MosaicHunter/$f3.MH.tsv; done | awk -v chr=$f1 -v pos=$f2 '$1==chr&&$2==pos' | wc -l; cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7==4||$7==5' | cut -f1 | while read f3; do awk '$7/($6+$7+$8)<0.3&&10^$12>0.5' MosaicHunter/$f3.MH.tsv; done | awk -v chr=$f1 -v pos=$f2 '$1==chr&&$2==pos' | wc -l; cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7==""' | cut -f1 | while read f3; do awk '$7/($6+$7+$8)<0.3&&10^$12>0.5' MosaicHunter/$f3.MH.tsv; done | awk -v chr=$f1 -v pos=$f2 '$1==chr&&$2==pos' | wc -l; done | paste - - - - - - > MosaicHunter/$f.filtered.check; done
	
	cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7==1||$7==2||$7==3||$7==4||$7==5' | cut -f1 | while read f; do my.grep -k 1,2 -c 1,2 -q <(awk '$3+$4+$5==1' MosaicHunter/$f.raw.check) -f MosaicHunter/$f.MH.tsv > MosaicHunter/$f.MH.stringent.tsv; done
	
	cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7==1||$7==2||$7==3' | cut -f1 | while read f; do my.grep -k 1,2 -c 1,2 -q <(awk '$5==0||($3+$4)/$5>=5' MosaicHunter/$f.filtered.check) -f MosaicHunter/$f.MH.tsv > MosaicHunter/$f.MH.loose.tsv; done
	cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7==4||$7==5' | cut -f1 | while read f; do my.grep -k 1,2 -c 1,2 -q <(awk '$3+$4==0||$5/($3+$4)>=5' MosaicHunter/$f.filtered.check) -f MosaicHunter/$f.MH.tsv > MosaicHunter/$f.MH.loose.tsv; done
	# further consider the p-value of proportion test: no additional mutations called from AD samples
	#cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7==1||$7==2||$7==3' | cut -f1 | while read f; do my.grep -k 1,2 -c 1,2 -q <(cat MosaicHunter/$f.filtered.check | ./propTest.pl | awk '$5==0||($3+$4)/$5>=5||($7<0.05&&$8>1&&$3+$4+$5<35)') -f MosaicHunter/$f.MH.tsv > MosaicHunter/$f.MH.loose.tsv; done
	#cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7==4||$7==5' | cut -f1 | while read f; do my.grep -k 1,2 -c 1,2 -q <(cat MosaicHunter/$f.filtered.check | ./propTest.pl | awk '$3+$4==0||$5/($3+$4)>=5||($7<0.05&&$8<1&&$3+$4+$5<35)') -f MosaicHunter/$f.MH.tsv > MosaicHunter/$f.MH.loose.tsv; done
	
	myjoin -m -F1 <(cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7!=""' | cut -f1 | while read f; do echo $f; wc -l MosaicHunter/$f.MH.stringent.tsv | cut -f1 -d " "; done | paste - -) -f1 AD_panel.sample.clinical.tsv | cut -f1,2,9 > AD_panel.MH.stringent.summary
	my.grep.v -k 1 -c 1 -q AD_panel.excluded.sample.list -f AD_panel.MH.stringent.summary | awk '$3==1' | awk '{sum1+=$2; if($2>0){sum2++}}END{print sum1/NR,sum2/NR}'
	my.grep.v -k 1 -c 1 -q AD_panel.excluded.sample.list -f AD_panel.MH.stringent.summary | awk '$3==2||$3==3' | awk '{sum1+=$2; if($2>0){sum2++}}END{print sum1/NR,sum2/NR}'
	my.grep.v -k 1 -c 1 -q AD_panel.excluded.sample.list -f AD_panel.MH.stringent.summary | awk '$3==4||$3==5' | awk '{sum1+=$2; if($2>0){sum2++}}END{print sum1/NR,sum2/NR}'
	
	mkdir -p ANNOVAR
	cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7!=""' | cut -f1 | while read f; do awk -v ID=$f '{OFS="\t"; print $0,ID}' MosaicHunter/$f.MH.stringent.tsv; done > ANNOVAR/AD_panel.MH.stringent.input
	annotate_variation.pl --geneanno --dbtype refgene --buildver hg19 --outfile ANNOVAR/AD_panel.MH.stringent <(awk '{OFS="\t"; print $1,$2,$2,$3,$4}' ANNOVAR/AD_panel.MH.stringent.input) ${REFERENCE_DIR}/human_annovar/
	annotate_variation.pl --filter --dbtype gnomad_genome --buildver hg19 --outfile ANNOVAR/AD_panel.MH.stringent <(awk '{OFS="\t"; print $1,$2,$2,$3,$4}' ANNOVAR/AD_panel.MH.stringent.input) ${REFERENCE_DIR}/human_annovar/
	annotate_variation.pl --filter --dbtype ljb26_all -otherinfo --buildver hg19 --outfile ANNOVAR/AD_panel.MH.stringent <(awk '{OFS="\t"; print $1,$2,$2,$3,$4}' ANNOVAR/AD_panel.MH.stringent.input) ${REFERENCE_DIR}/human_annovar/
	annotate_variation.pl --filter --dbtype cosmic70 --buildver hg19 --outfile ANNOVAR/AD_panel.MH.stringent <(awk '{OFS="\t"; print $1,$2,$2,$3,$4}' ANNOVAR/AD_panel.MH.stringent.input) ${REFERENCE_DIR}/human_annovar/
	myjoin -F1,2,3,4 ANNOVAR/AD_panel.MH.stringent.input -f3,5,6,7 ANNOVAR/AD_panel.MH.stringent.hg19_gnomad_genome_dropped | awk '{OFS="\t"; if($1=="="){print $2,$3,$4,$5,$6,$7,$8,$9,$17,$19} if($1=="+"){print $2,$3,$4,$5,$6,$7,$8,$9,$17,0}}' | uniq > ANNOVAR/AD_panel.MH.stringent.tmp1
	myjoin -F1,2,3,4 ANNOVAR/AD_panel.MH.stringent.tmp1 -f3,5,6,7 ANNOVAR/AD_panel.MH.stringent.variant_function | awk '$1=="="||$1=="+"' | cut -f2-13 | uniq > ANNOVAR/AD_panel.MH.stringent.tmp2
	myjoin -F1,2,3,4 ANNOVAR/AD_panel.MH.stringent.tmp2 -f4,6,7,8 ANNOVAR/AD_panel.MH.stringent.exonic_variant_function | awk '$1=="="||$1=="+"' | cut -f2-13,15,16 | sed -e 's/ SNV//g' | uniq > AD_panel.MH.stringent.tsv
	cat <(cat ANNOVAR/AD_panel.MH.stringent.hg19_ljb26_all_dropped | awk '{split($2,array,","); if(array[2]=="D"||array[4]=="D"){print $3"\t"$4}}') <(awk '$1=="splicing"' ANNOVAR/AD_panel.MH.stringent.variant_function | cut -f3,4) <(awk '$2~"stop"' ANNOVAR/AD_panel.MH.stringent.exonic_variant_function | cut -f4,5) | sort | uniq > ANNOVAR/AD_panel.MH.stringent.deleterious
	myjoin -F1,2 <(myjoin -F3,5,7 ANNOVAR/AD_panel.MH.stringent.variant_function -f4,6,8 ANNOVAR/AD_panel.MH.stringent.exonic_variant_function | awk -F "\t" '{OFS="\t";split($3,a,"(");symbol=a[1];if($1=="="){print $4,$6,$7,$8,symbol,$2,$10}if($1=="+"){print $4,$6,$7,$8,symbol,$2,"NA"}}') -f1,2 ANNOVAR/AD_panel.MH.stringent.deleterious | awk -F "\t" '{OFS="\t";if($1=="="){print $2,$3,$4,$5,$6,$7,$8,"deleterious"}if($1=="+"){print $2,$3,$4,$5,$6,$7,$8,"neutral"}}' | sed -e 's/ SNV//g' | sort | uniq > AD_panel.MH.stringent.gene_anno.tsv
	rm -f ANNOVAR/AD_panel.MH.stringent.tmp* ANNOVAR/AD_panel.MH.stringent.log
	
	cat <(echo "#CHROM_POS_ID_REF_ALT_QUAL_FILTER" | sed -e 's/_/\t/g') <(cut -f1-4 AD_panel.MH.stringent.tsv | sort -k1,1n -k2,2n | uniq | awk '{OFS="\t";print "chr"$1,$2,$1":"$2"_"$3"/"$4,$3,$4,".","PASS"}') > AD_panel.MH.stringent.vcf
	
	myjoin -m -F1 <(cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7!=""' | cut -f1 | while read f; do echo $f; wc -l MosaicHunter/$f.MH.loose.tsv | cut -f1 -d " "; done | paste - -) -f1 AD_panel.sample.clinical.tsv | cut -f1,2,9 > AD_panel.MH.loose.summary
	my.grep.v -k 1 -c 1 -q AD_panel.excluded.sample.list -f AD_panel.MH.loose.summary | awk '$3==1' | awk '{sum1+=$2; if($2>0){sum2++}}END{print sum1/NR,sum2/NR}'
	my.grep.v -k 1 -c 1 -q AD_panel.excluded.sample.list -f AD_panel.MH.loose.summary | awk '$3==2||$3==3' | awk '{sum1+=$2; if($2>0){sum2++}}END{print sum1/NR,sum2/NR}'
	my.grep.v -k 1 -c 1 -q AD_panel.excluded.sample.list -f AD_panel.MH.loose.summary | awk '$3==4||$3==5' | awk '{sum1+=$2; if($2>0){sum2++}}END{print sum1/NR,sum2/NR}'
	
	mkdir -p ANNOVAR
	cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7!=""' | cut -f1 | while read f; do awk -v ID=$f '{OFS="\t"; print $0,ID}' MosaicHunter/$f.MH.loose.tsv; done > ANNOVAR/AD_panel.MH.loose.input
	annotate_variation.pl --geneanno --dbtype refgene --buildver hg19 --outfile ANNOVAR/AD_panel.MH.loose <(awk '{OFS="\t"; print $1,$2,$2,$3,$4}' ANNOVAR/AD_panel.MH.loose.input) ${REFERENCE_DIR}/human_annovar/
	annotate_variation.pl --filter --dbtype gnomad_genome --buildver hg19 --outfile ANNOVAR/AD_panel.MH.loose <(awk '{OFS="\t"; print $1,$2,$2,$3,$4}' ANNOVAR/AD_panel.MH.loose.input) ${REFERENCE_DIR}/human_annovar/
	annotate_variation.pl --filter --dbtype ljb26_all -otherinfo --buildver hg19 --outfile ANNOVAR/AD_panel.MH.loose <(awk '{OFS="\t"; print $1,$2,$2,$3,$4}' ANNOVAR/AD_panel.MH.loose.input) ${REFERENCE_DIR}/human_annovar/
	annotate_variation.pl --filter --dbtype cosmic70 --buildver hg19 --outfile ANNOVAR/AD_panel.MH.loose <(awk '{OFS="\t"; print $1,$2,$2,$3,$4}' ANNOVAR/AD_panel.MH.loose.input) ${REFERENCE_DIR}/human_annovar/
	myjoin -F1,2,3,4 ANNOVAR/AD_panel.MH.loose.input -f3,5,6,7 ANNOVAR/AD_panel.MH.loose.hg19_gnomad_genome_dropped | awk '{OFS="\t"; if($1=="="){print $2,$3,$4,$5,$6,$7,$8,$9,$17,$19} if($1=="+"){print $2,$3,$4,$5,$6,$7,$8,$9,$17,0}}' | uniq > ANNOVAR/AD_panel.MH.loose.tmp1
	myjoin -F1,2,3,4 ANNOVAR/AD_panel.MH.loose.tmp1 -f3,5,6,7 ANNOVAR/AD_panel.MH.loose.variant_function | awk '$1=="="||$1=="+"' | cut -f2-13 | uniq > ANNOVAR/AD_panel.MH.loose.tmp2
	myjoin -F1,2,3,4 ANNOVAR/AD_panel.MH.loose.tmp2 -f4,6,7,8 ANNOVAR/AD_panel.MH.loose.exonic_variant_function | awk '$1=="="||$1=="+"' | cut -f2-13,15,16 | sed -e 's/ SNV//g' | uniq > AD_panel.MH.loose.tsv
	cat <(cat ANNOVAR/AD_panel.MH.loose.hg19_ljb26_all_dropped | awk '{split($2,array,","); if(array[2]=="D"||array[4]=="D"){print $3"\t"$4}}') <(awk '$1=="splicing"' ANNOVAR/AD_panel.MH.loose.variant_function | cut -f3,4) <(awk '$2~"stop"' ANNOVAR/AD_panel.MH.loose.exonic_variant_function | cut -f4,5) | sort | uniq > ANNOVAR/AD_panel.MH.loose.deleterious
	myjoin -F1,2 <(myjoin -F3,5,7 ANNOVAR/AD_panel.MH.loose.variant_function -f4,6,8 ANNOVAR/AD_panel.MH.loose.exonic_variant_function | awk -F "\t" '{OFS="\t";split($3,a,"(");symbol=a[1];if($1=="="){print $4,$6,$7,$8,symbol,$2,$10}if($1=="+"){print $4,$6,$7,$8,symbol,$2,"NA"}}') -f1,2 ANNOVAR/AD_panel.MH.loose.deleterious | awk -F "\t" '{OFS="\t";if($1=="="){print $2,$3,$4,$5,$6,$7,$8,"deleterious"}if($1=="+"){print $2,$3,$4,$5,$6,$7,$8,"neutral"}}' | sed -e 's/ SNV//g' | sort | uniq > AD_panel.MH.loose.gene_anno.tsv
	rm -f ANNOVAR/AD_panel.MH.loose.tmp* ANNOVAR/AD_panel.MH.loose.log
	
	cat <(echo "#CHROM_POS_ID_REF_ALT_QUAL_FILTER" | sed -e 's/_/\t/g') <(cut -f1-4 AD_panel.MH.loose.tsv | sort -k1,1n -k2,2n | uniq | awk '{OFS="\t";print "chr"$1,$2,$1":"$2"_"$3"/"$4,$3,$4,".","PASS"}') > AD_panel.MH.loose.vcf
}

SUMMARY_INDEL ()
{
	# file format: chr pos count_NCI count_MCI count_AD count_NA
	grep "done" AD_panel.sample.list | cut -f1 | while read f; do grep PASS Pisces/$f.final.vcf | awk '$10~"0/1"' | awk 'length($4)>1||length($5)>1' | awk '{split($10,a,":");split(a[3],b,",");if(b[2]>3&&a[5]<0.3){print $0}}' | cut -f1,2 | while read f1 f2; do echo $f1; echo $f2; cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7==1' | cut -f1 | while read f3; do awk 'length($4)>1||length($5)>1' Pisces/$f3.final.vcf; done | awk -v chr=$f1 -v pos=$f2 '$1==chr&&$2==pos' | wc -l; cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7==2||$7==3' | cut -f1 | while read f3; do awk 'length($4)>1||length($5)>1' Pisces/$f3.final.vcf; done | awk -v chr=$f1 -v pos=$f2 '$1==chr&&$2==pos' | wc -l; cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7==4||$7==5' | cut -f1 | while read f3; do awk 'length($4)>1||length($5)>1' Pisces/$f3.final.vcf; done | awk -v chr=$f1 -v pos=$f2 '$1==chr&&$2==pos' | wc -l; cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7==""' | cut -f1 | while read f3; do awk 'length($4)>1||length($5)>1' Pisces/$f3.final.vcf; done | awk -v chr=$f1 -v pos=$f2 '$1==chr&&$2==pos' | wc -l; done | paste - - - - - - > Pisces/$f.raw.check; done
	
	cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7==1||$7==2||$7==3||$7==4||$7==5' | cut -f1 | while read f; do my.grep -k 1,2 -c 1,2 -q <(awk '$3+$4+$5==1' Pisces/$f.raw.check) -f Pisces/$f.final.vcf > Pisces/$f.stringent.vcf; done
	
	cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7==1||$7==2||$7==3' | cut -f1 | while read f; do my.grep -k 1,2 -c 1,2 -q <(awk '$5==0||($3+$4)/$5>=5' Pisces/$f.raw.check) -f Pisces/$f.final.vcf > Pisces/$f.loose.vcf; done
	cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7==4||$7==5' | cut -f1 | while read f; do my.grep -k 1,2 -c 1,2 -q <(awk '$3+$4==0||$5/($3+$4)>=5' Pisces/$f.raw.check) -f Pisces/$f.final.vcf > Pisces/$f.loose.vcf; done
	
	myjoin -m -F1 <(cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7!=""' | cut -f1 | while read f; do echo $f; wc -l Pisces/$f.stringent.vcf | cut -f1 -d " "; done | paste - -) -f1 AD_panel.sample.clinical.tsv | cut -f1,2,9 > AD_panel.indel.stringent.summary
	my.grep.v -k 1 -c 1 -q AD_panel.excluded.sample.list -f AD_panel.indel.stringent.summary | awk '$3==1' | awk '{sum1+=$2; if($2>0){sum2++}}END{print sum1/NR,sum2/NR}'
	my.grep.v -k 1 -c 1 -q AD_panel.excluded.sample.list -f AD_panel.indel.stringent.summary | awk '$3==2||$3==3' | awk '{sum1+=$2; if($2>0){sum2++}}END{print sum1/NR,sum2/NR}'
	my.grep.v -k 1 -c 1 -q AD_panel.excluded.sample.list -f AD_panel.indel.stringent.summary | awk '$3==4||$3==5' | awk '{sum1+=$2; if($2>0){sum2++}}END{print sum1/NR,sum2/NR}'
	
	mkdir -p ANNOVAR
	cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7!=""' | cut -f1 | while read f; do convert2annovar.pl -format vcf4 -includeinfo Pisces/$f.stringent.vcf | awk -v ID=$f '{OFS="\t"; print $1,$2,$3,$4,$5,$15,ID}'; done | awk '$4=="-"||$5=="-"' | awk '{split($6,a,":");split(a[3],b,",");if(b[2]>3&&a[5]<0.3){print $0}}' > ANNOVAR/AD_panel.indel.stringent.input
	annotate_variation.pl --geneanno --dbtype refgene --buildver hg19 --outfile ANNOVAR/AD_panel.indel.stringent <(cut -f1-5 ANNOVAR/AD_panel.indel.stringent.input) ${REFERENCE_DIR}/human_annovar/
	annotate_variation.pl --filter --dbtype gnomad_genome --buildver hg19 --outfile ANNOVAR/AD_panel.indel.stringent <(cut -f1-5 ANNOVAR/AD_panel.indel.stringent.input) ${REFERENCE_DIR}/human_annovar/
	myjoin -F1,2,3,4,5 ANNOVAR/AD_panel.indel.stringent.input -f3,4,5,6,7 ANNOVAR/AD_panel.indel.stringent.hg19_gnomad_genome_dropped | awk '{OFS="\t"; if($1=="="){print $2,$3,$4,$5,$6,$7,$8,$10} if($1=="+"){print $2,$3,$4,$5,$6,$7,$8,0}}' | uniq > ANNOVAR/AD_panel.indel.stringent.tmp1
	myjoin -F1,2,3,4,5 ANNOVAR/AD_panel.indel.stringent.tmp1 -f3,4,5,6,7 ANNOVAR/AD_panel.indel.stringent.variant_function | awk '$1=="="||$1=="+"' | cut -f2-11 | uniq > ANNOVAR/AD_panel.indel.stringent.tmp2
	myjoin -F1,2,3,4,5 ANNOVAR/AD_panel.indel.stringent.tmp2 -f4,5,6,7,8 ANNOVAR/AD_panel.indel.stringent.exonic_variant_function | awk '$1=="="||$1=="+"' | cut -f2-11,13,14 | uniq > AD_panel.indel.stringent.tsv
	cat <(awk '$1=="splicing"' ANNOVAR/AD_panel.indel.stringent.variant_function | cut -f3,4,5) <(awk '$2~"^frameshift"||$2~"stop"' ANNOVAR/AD_panel.indel.stringent.exonic_variant_function | cut -f4,5,6) | sort | uniq > ANNOVAR/AD_panel.indel.stringent.deleterious
	myjoin -F1,2,3 <(myjoin -F3,4,5,6,7 ANNOVAR/AD_panel.indel.stringent.variant_function -f4,5,6,7,8 ANNOVAR/AD_panel.indel.stringent.exonic_variant_function | awk -F "\t" '{OFS="\t";split($3,a,"(");symbol=a[1];if($1=="="){print $4,$5,$6,$7,$8,symbol,$2,$10}if($1=="+"){print $4,$5,$6,$7,$8,symbol,$2,"NA"}}') -f1,2,3 ANNOVAR/AD_panel.indel.stringent.deleterious | awk -F "\t" '{OFS="\t";if($1=="="){print $2,$3,$4,$5,$6,$7,$8,$9,"deleterious"}if($1=="+"){print $2,$3,$4,$5,$6,$7,$8,$9,"neutral"}}' | sort | uniq > AD_panel.indel.stringent.gene_anno.tsv
	rm -f ANNOVAR/AD_panel.indel.stringent.tmp* ANNOVAR/AD_panel.indel.stringent.log
	
	myjoin -m -F1 <(cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7!=""' | cut -f1 | while read f; do echo $f; wc -l Pisces/$f.loose.vcf | cut -f1 -d " "; done | paste - -) -f1 AD_panel.sample.clinical.tsv | cut -f1,2,9 > AD_panel.indel.loose.summary
	my.grep.v -k 1 -c 1 -q AD_panel.excluded.sample.list -f AD_panel.indel.loose.summary | awk '$3==1' | awk '{sum1+=$2; if($2>0){sum2++}}END{print sum1/NR,sum2/NR}'
	my.grep.v -k 1 -c 1 -q AD_panel.excluded.sample.list -f AD_panel.indel.loose.summary | awk '$3==2||$3==3' | awk '{sum1+=$2; if($2>0){sum2++}}END{print sum1/NR,sum2/NR}'
	my.grep.v -k 1 -c 1 -q AD_panel.excluded.sample.list -f AD_panel.indel.loose.summary | awk '$3==4||$3==5' | awk '{sum1+=$2; if($2>0){sum2++}}END{print sum1/NR,sum2/NR}'
	
	mkdir -p ANNOVAR
	cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7!=""' | cut -f1 | while read f; do convert2annovar.pl -format vcf4 -includeinfo Pisces/$f.loose.vcf | awk -v ID=$f '{OFS="\t"; print $1,$2,$3,$4,$5,$15,ID}'; done | awk '$4=="-"||$5=="-"' | awk '{split($6,a,":");split(a[3],b,",");if(b[2]>3&&a[5]<0.3){print $0}}' > ANNOVAR/AD_panel.indel.loose.input
	annotate_variation.pl --geneanno --dbtype refgene --buildver hg19 --outfile ANNOVAR/AD_panel.indel.loose <(cut -f1-5 ANNOVAR/AD_panel.indel.loose.input) ${REFERENCE_DIR}/human_annovar/
	annotate_variation.pl --filter --dbtype gnomad_genome --buildver hg19 --outfile ANNOVAR/AD_panel.indel.loose <(cut -f1-5 ANNOVAR/AD_panel.indel.loose.input) ${REFERENCE_DIR}/human_annovar/
	myjoin -F1,2,3,4,5 ANNOVAR/AD_panel.indel.loose.input -f3,4,5,6,7 ANNOVAR/AD_panel.indel.loose.hg19_gnomad_genome_dropped | awk '{OFS="\t"; if($1=="="){print $2,$3,$4,$5,$6,$7,$8,$10} if($1=="+"){print $2,$3,$4,$5,$6,$7,$8,0}}' | uniq > ANNOVAR/AD_panel.indel.loose.tmp1
	myjoin -F1,2,3,4,5 ANNOVAR/AD_panel.indel.loose.tmp1 -f3,4,5,6,7 ANNOVAR/AD_panel.indel.loose.variant_function | awk '$1=="="||$1=="+"' | cut -f2-11 | uniq > ANNOVAR/AD_panel.indel.loose.tmp2
	myjoin -F1,2,3,4,5 ANNOVAR/AD_panel.indel.loose.tmp2 -f4,5,6,7,8 ANNOVAR/AD_panel.indel.loose.exonic_variant_function | awk '$1=="="||$1=="+"' | cut -f2-11,13,14 | uniq > AD_panel.indel.loose.tsv
	cat <(awk '$1=="splicing"' ANNOVAR/AD_panel.indel.loose.variant_function | cut -f3,4,5) <(awk '$2~"^frameshift"||$2~"stop"' ANNOVAR/AD_panel.indel.loose.exonic_variant_function | cut -f4,5,6) | sort | uniq > ANNOVAR/AD_panel.indel.loose.deleterious
	myjoin -F1,2,3 <(myjoin -F3,4,5,6,7 ANNOVAR/AD_panel.indel.loose.variant_function -f4,5,6,7,8 ANNOVAR/AD_panel.indel.loose.exonic_variant_function | awk -F "\t" '{OFS="\t";split($3,a,"(");symbol=a[1];if($1=="="){print $4,$5,$6,$7,$8,symbol,$2,$10}if($1=="+"){print $4,$5,$6,$7,$8,symbol,$2,"NA"}}') -f1,2,3 ANNOVAR/AD_panel.indel.loose.deleterious | awk -F "\t" '{OFS="\t";if($1=="="){print $2,$3,$4,$5,$6,$7,$8,$9,"deleterious"}if($1=="+"){print $2,$3,$4,$5,$6,$7,$8,$9,"neutral"}}' | sort | uniq > AD_panel.indel.loose.gene_anno.tsv
	rm -f ANNOVAR/AD_panel.indel.loose.tmp* ANNOVAR/AD_panel.indel.loose.log
}

EXTRACT_CONTROL_VCF ()
{
	mkdir -p WGS_vcf
	
	myjoin -m <(cut -f8 AD_panel.sample.clinical.tsv) <(sed -e 's/,/\t/g' ROSMAP_WGSkey.csv) | cut -f1,3 > WGS_vcf/AD_panel.tmp1
	cut -f2 WGS_vcf/AD_panel.sample.tmp1 | while read f; do echo $f; sed -e 's/"//g' ROSMAP_biospecimen_metadata.csv | sed -e 's/,/\t/g' | awk -v name=$f 'BEGIN{sample="NA"}{if($1==name||$2==name){sample=$5}}END{print sample}'; done | paste - - > WGS_vcf/AD_panel.tmp2
	myjoin -m -F2 -f1 WGS_vcf/AD_panel.tmp1 WGS_vcf/AD_panel.tmp2 | cut -f1,3- > WGS_vcf/AD_panel.list
	rm -f WGS_vcf/AD_panel.tmp1 WGS_vcf/AD_panel.tmp2
	
	SP_for_parallel _num=$(cut -f1 WGS_vcf/AD_panel.list | sort | uniq)
	{
		run_gatk_3.6.sh -T SelectVariants -R ${REFERENCE_DIR}/human_v37/human_g1k_v37.fasta -V ROSMAP_WGS.tsv.gz -o WGS_vcf/${_num}.control.SNP.vcf $(awk -F "," -v name=${_num} '{if($1==name){printf "-sn "$2" "}}' ROSMAP_WGSkey.csv) -selectType SNP -env -ef -L 3277911_Covered.b37.bed
	}
	
	myjoin -m -F9 -f1 <(cut -f1-10 AD_panel.MH.loose.tsv) AD_panel.sample.clinical.tsv | cut -f1,2,9,18 | while read chr pos id1 id2; do awk -v id1=$id1 -v id2=$id2 -v chr=$chr -v pos=$pos '{if($1==chr&&$2==pos){OFS="\t"; print $0,id1,id2}}' WGS_vcf/$id2.control.SNP.vcf; done > WGS_vcf/AD_panel.MH.loose.vcf
	
	myjoin -m -F1,2,9 -f1,2,11 AD_panel.MH.loose.tsv WGS_vcf/AD_panel.MH.loose.vcf | awk '$10<0.0001&&$6+$7>100'
}

SIGNATURE_POWER_CORRECTION ()
{
	mkdir -p power_correction
	
	fastaFromBed -fi ${REFERENCE_DIR}/human_hg19_Broad_hs37d5/human_hg19_Broad_hs37d5.fasta -bed 3277911_Covered.b37.bed -fo power_correction/AD_panel.powered.fasta
	compseq -sequence power_correction/AD_panel.powered.fasta -word 3 -outfile power_correction/AD_panel.powered.tmp -reverse Y
	cat power_correction/AD_panel.powered.tmp | grep -v "^#" | awk 'length($1)==3' > power_correction/AD_panel.powered.composition
	
	rm -rf power_correction/AD_panel.powered.tmp
}

PREP_MAFTOOLS ()
{
	cat <(awk '{OFS="\t"; print $2,$3,$3,$4,$5,$1,$13,$19}' MAFTools/AD_panel.MH.loose.merged_filtered.tsv | grep -v "^Chr") <(awk '{OFS="\t"; print $2,$3,$4,$5,$6,$1,$16,$22}' MAFTools/AD_panel.indel.loose.merged_filtered.tsv | grep -v "^Chr") > MAFTools/AD_panel.both.loose.input
	table_annovar.pl MAFTools/AD_panel.both.loose.input ${REFERENCE_DIR}/human_annovar/ --buildver hg19 --outfile MAFTools/AD_panel.both.loose --otherinfo --remove --protocol refGene --operation g --nastring NA
	sed -e 's/Otherinfo/ID\tMAF\tCogdx/g' MAFTools/AD_panel.both.loose.hg19_multianno.txt | awk -F "\t" '{OFS="\t";split($6,a,";");split($9,b,";");print $1,$2,$3,$4,$5,a[1],$7,$8,b[1],$10,$11,$12,$13}' > MAFTools/AD_panel.both.loose.hg19_multianno.txt1
	mv -f MAFTools/AD_panel.both.loose.hg19_multianno.txt1 MAFTools/AD_panel.both.loose.hg19_multianno.txt
}

MISC ()
{
	grep successfully slurm-* | cut -f1 -d ":" | while read f; do head $f | grep "seqpipe -m run.pipe identification" | cut -f3 -d "="; done > temp
	myjoin -F1 AD_panel.sample.list -f1 temp | awk '{OFS="\t"; if($1=="="){print $2,$3,"done"}if($1=="+"){print $2,$3,$4}}' > AD_panel.sample.list1
	mv -f AD_panel.sample.list1 AD_panel.sample.list
	grep successfully slurm-* | cut -f1 -d ":" | while read f; do rm -f $f; done
	
	# extract recurrent COSMIC mutations in AD and control; occurrence >= 20
	my.grep -k 1 -c 9 -q <(cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7==4||$7==5') -f <(my.grep -k 3,5,6,7 -c 1,2,3,4 -q <(awk '{split($2,a,"=");split(a[3],b,",");sum=0;for(i=1;i<=length(b);i++){split(b[i],c,"(");sum+=c[1]};if(sum>=20){print $0}}' ANNOVAR/AD_panel.MH.loose.hg19_cosmic70_dropped) -f AD_panel.MH.loose.tsv)
	my.grep -k 1 -c 9 -q <(cat AD_panel.sample.clinical.tsv | awk -F "\t" '$7==1') -f <(my.grep -k 3,5,6,7 -c 1,2,3,4 -q <(awk '{split($2,a,"=");split(a[3],b,",");sum=0;for(i=1;i<=length(b);i++){split(b[i],c,"(");sum+=c[1]};if(sum>=20){print $0}}' ANNOVAR/AD_panel.MH.loose.hg19_cosmic70_dropped) -f AD_panel.MH.loose.tsv)
	
	awk '$7>3&&10^$12>0.5' MosaicHunter/318.MH.tsv | awk '$1==11' > ANNOVAR/318.chr11.input
	annotate_variation.pl --geneanno --dbtype refgene --buildver hg19 --outfile ANNOVAR/318.chr11 <(awk '{OFS="\t"; print $1,$2,$2,$3,$4}' ANNOVAR/318.chr11.input) ${REFERENCE_DIR}/human_annovar/
	annotate_variation.pl --filter --dbtype gnomad_genome --buildver hg19 --outfile ANNOVAR/318.chr11 <(awk '{OFS="\t"; print $1,$2,$2,$3,$4}' ANNOVAR/318.chr11.input) ${REFERENCE_DIR}/human_annovar/
	myjoin -F1,2,3,4,5 ANNOVAR/318.chr11.input -f3,4,5,6,7 ANNOVAR/318.chr11.hg19_gnomad_genome_dropped | awk '{OFS="\t"; if($1=="="){print $2,$3,$4,$5,$6,$7,$8,$10} if($1=="+"){print $2,$3,$4,$5,$6,$7,$8,0}}' | uniq > ANNOVAR/318.chr11.tmp1
	myjoin -F1,2,3,4,5 ANNOVAR/318.chr11.tmp1 -f3,4,5,6,7 ANNOVAR/318.chr11.variant_function | awk '$1=="="||$1=="+"' | cut -f2-11 | uniq > ANNOVAR/318.chr11.tmp2
	myjoin -F1,2,3,4,5 ANNOVAR/318.chr11.tmp2 -f4,5,6,7,8 ANNOVAR/318.chr11.exonic_variant_function | awk '$1=="="||$1=="+"' | cut -f2-11,13,14 | uniq > 318.chr11.tsv
	cat <(awk '$1=="splicing"' ANNOVAR/318.chr11.variant_function | cut -f3,4,5) <(awk '$2~"^frameshift"||$2~"stop"' ANNOVAR/318.chr11.exonic_variant_function | cut -f4,5,6) | sort | uniq > ANNOVAR/318.chr11.deleterious
	myjoin -F1,2,3 <(myjoin -F3,4,5,6,7 ANNOVAR/318.chr11.variant_function -f4,5,6,7,8 ANNOVAR/318.chr11.exonic_variant_function | awk -F "\t" '{OFS="\t";split($3,a,"(");symbol=a[1];if($1=="="){print $4,$5,$6,$7,$8,symbol,$2,$10}if($1=="+"){print $4,$5,$6,$7,$8,symbol,$2,"NA"}}') -f1,2,3 ANNOVAR/318.chr11.deleterious | awk -F "\t" '{OFS="\t";if($1=="="){print $2,$3,$4,$5,$6,$7,$8,$9,"deleterious"}if($1=="+"){print $2,$3,$4,$5,$6,$7,$8,$9,"neutral"}}' | sort | uniq > 318.chr11.gene_anno.tsv
	rm -f ANNOVAR/318.chr11.tmp* ANNOVAR/318.chr11.log
}


#PREPARATION
while read LINE; do
	sbatch -J $LINE -o ${LINE}_fixXI.log --mem=8G -t 0-12:00 -N 1 -c 4 -p short --mail-user=yilanwang@g.harvard.edu --mail-type=FAIL,END --wrap="bash $SCRIPT_DIR/variant_calling/identification.sh $LINE 4"
done < $INPUT_DIR/barcode_id.txt
