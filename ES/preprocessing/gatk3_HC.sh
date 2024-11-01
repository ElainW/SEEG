#!/bin/bash
INDIR=$1
PREFIX=$2
INTERVAL=$3
OUTDIR1=$4
OUTDIR2=$5 # update this for two-step
OUTDIR3=$6
SEX=$7

mkdir -p $OUTDIR2
mkdir -p $OUTDIR3

MOSAICHUNTER_DIR=... # git clone https://github.com/zzhang526/MosaicHunter.git
SCRIPT_DIR=../../panel_seq/variant_calling
TOOLS_DIR=../../tools

export PATH="$TOOLS_DIR/:$SCRIPT_DIR/:$PATH"

samtools view -h -f 0x2 $INDIR/$PREFIX.bam | perl -ne 'print if (/^@/||(/NM:i:(\d+)/&&$1<=4))' | samtools view -Sb - > $INDIR/$PREFIX.final.bam
samtools index $INDIR/$PREFIX.final.bam
$SCRIPT_DIR/run_gatk_3.6.sh -T HaplotypeCaller \
	-R $REFERENCE_DIR/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta \
	--dbsnp Homo_sapiens_assembly19.dbsnp138.vcf \
	-l INFO \
	-rf BadCigar \
	-ploidy 2 \
	-I $INDIR/$PREFIX.final.bam \
	-o $OUTDIR1/$PREFIX.HC.vcf \
	-L $INTERVAL

select indels
$SCRIPT_DIR/run_gatk_3.6.sh -T SelectVariants \
	-R $REFERENCE_DIR/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta \
	-V $OUTDIR1/$PREFIX.HC.vcf \
	--selectTypeToInclude INDEL \
	-o $OUTDIR1/$PREFIX.HC.indel.vcf \

slopBed -i <(grep -v ^# $OUTDIR1/$PREFIX.HC.indel.vcf | awk '{OFS="\t"; print $1,$2-1,$2}') -g $REFERENCE_DIR/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta.fai -b 5 > $OUTDIR1/$PREFIX.HC.nearindel.bed

# mosaichunter command
# originally ran it using pre-specified parameters
#java -Xmx64G -jar ${MOSAICHUNTER_DIR}/build/mosaichunter.jar -C epilepsy.properties -P input_file=$INDIR/$PREFIX.final.bam -P mosaic_filter.sex=F -P output_dir=$OUTDIR2/$PREFIX -P indel_region_filter.bed_file=$OUTDIR1/$PREFIX.HC.nearindel.bed
#rm -f $OUTDIR2/$PREFIX/misaligned_reads_filter.psl

# now running it in two steps
# first estimate the alpha, beta, average depth parameters
java -Xmx64G -jar ${MOSAICHUNTER_DIR}/build/mosaichunter.jar exome_parameters -P input_file=$INDIR/$PREFIX.final.bam -P output_dir=$OUTDIR2/$PREFIX -P reference_file=/home/yh174/reference/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta -P heterozygous_filter.sex=$SEX -P indel_region_filter.bed_file=$OUTDIR1/$PREFIX.HC.nearindel.bed
# manually change mosaic_filter.alpha_param, mosaic_filter.beta_param and syscall_filter.depth
java -Xmx64G -jar ${MOSAICHUNTER_DIR}/build/mosaichunter.jar -C $OUTDIR2/$PREFIX/epilepsy.properties -P input_file=$INDIR/$PREFIX.final.bam -P mosaic_filter.sex=$SEX -P output_dir=$OUTDIR3/$PREFIX -P indel_region_filter.bed_file=$OUTDIR1/$PREFIX.HC.nearindel.bed

