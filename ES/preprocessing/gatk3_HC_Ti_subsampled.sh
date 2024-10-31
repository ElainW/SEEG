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

MOSAICHUNTER_DIR=/home/yh174/tools/MosaicHunter_new
SCRIPT_DIR=/n/data1/bch/genetics/lee/elain/TLE/scripts/ras_panel/variantcalling
TOOLS_DIR=/home/yh174/tools
# need to define epilepsy.properties

# check out /n/data1/bch/genetics/lee/August/epilepsy/run.pipe (2022-09-04)
# may switch to GATK3(.6?)
# run_gatk_3.6.sh -T HaplotypeCaller -R ${REFERENCE_DIR}/human_v38_Broad/human_v38_Broad.fasta --dbsnp ${REFERENCE_DIR}/dbsnp_138.b38.vcf -I finalBam/${BARCODE_ID}.final.bam -l INFO -rf BadCigar -ploidy 2 -o GATK/${BARCODE_ID}.vcf -L Epi25K_29candidates.extended.bed
# run_gatk_3.6.sh -T SelectVariants -R ${REFERENCE_DIR}/human_v38_Broad/human_v38_Broad.fasta -V GATK/${BARCODE_ID}.vcf --selectTypeToInclude INDEL -o GATK/${BARCODE_ID}.indel.vcf
# slopBed -i <(grep -v ^# GATK/${BARCODE_ID}.indel.vcf | awk '{OFS="\t"; print $1,$2-1,$2}') -g ${REFERENCE_DIR}/human_v38_Broad/human_v38_Broad.genome -b 5 > GATK/${BARCODE_ID}.nearindel.bed

export PATH="$TOOLS_DIR/:$SCRIPT_DIR/:$PATH"

#samtools view -h -f 0x2 $INDIR/$PREFIX.bam | perl -ne 'print if (/^@/||(/NM:i:(\d+)/&&$1<=4))' | samtools view -Sb - > $INDIR/$PREFIX.final.bam
#samtools index $INDIR/$PREFIX.final.bam
#$SCRIPT_DIR/run_gatk_3.6.sh -T HaplotypeCaller \
	#-R /home/yh174/reference/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta \
	#--dbsnp /n/groups/walsh/indData/elain/databases/Homo_sapiens_assembly19.dbsnp138.vcf \
	#-l INFO \
	#-rf BadCigar \
	#-ploidy 2 \
	#-I $INDIR/$PREFIX.final.bam \
	#-o $OUTDIR1/$PREFIX.HC.vcf \
	#-L $INTERVAL

# select indels
#$SCRIPT_DIR/run_gatk_3.6.sh -T SelectVariants \
	#-R /home/yh174/reference/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta \
	#-V $OUTDIR1/$PREFIX.HC.vcf \
	#--selectTypeToInclude INDEL \
	#-o $OUTDIR1/$PREFIX.HC.indel.vcf \

#slopBed -i <(grep -v ^# $OUTDIR1/$PREFIX.HC.indel.vcf | awk '{OFS="\t"; print $1,$2-1,$2}') -g /home/yh174/reference/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta.fai -b 5 > $OUTDIR1/$PREFIX.HC.nearindel.bed

# mosaichunter command
# originally ran it using pre-specified parameters
#java -Xmx64G -jar ${MOSAICHUNTER_DIR}/build/mosaichunter.jar -C epilepsy.properties -P input_file=$INDIR/$PREFIX.final.bam -P mosaic_filter.sex=F -P output_dir=$OUTDIR2/$PREFIX -P indel_region_filter.bed_file=$OUTDIR1/$PREFIX.HC.nearindel.bed
#rm -f $OUTDIR2/$PREFIX/misaligned_reads_filter.psl

# now running it in two steps
# first estimate the alpha, beta, average depth parameters
if [ ! -f $INDIR/$PREFIX.final.bam.bai ]; then
	samtools index $INDIR/$PREFIX.final.bam
fi
# java -Xmx64G -jar ${MOSAICHUNTER_DIR}/build/mosaichunter.jar exome_parameters -P input_file=$INDIR/$PREFIX.final.bam -P output_dir=$OUTDIR2/subsampled_$PREFIX -P reference_file=/home/yh174/reference/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta -P heterozygous_filter.sex=$SEX -P indel_region_filter.bed_file=$OUTDIR1/$PREFIX.HC.nearindel.bed > $OUTDIR2/subsampled_$PREFIX/epilepsy.properties
# manually change mosaic_filter.alpha_param, mosaic_filter.beta_param and syscall_filter.depth
java -Xmx64G -jar ${MOSAICHUNTER_DIR}/build/mosaichunter.jar -C $OUTDIR2/subsampled_$PREFIX/epilepsy.properties -P input_file=$INDIR/$PREFIX.final.bam -P mosaic_filter.sex=$SEX -P output_dir=$OUTDIR3/subsampled_$PREFIX -P indel_region_filter.bed_file=$OUTDIR1/$PREFIX.HC.nearindel.bed

