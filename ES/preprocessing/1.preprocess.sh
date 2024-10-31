#!/bin/bash
module load gcc/6.2.0 java/jdk-1.8u112 bwa/0.7.15 samtools/0.1.19

folder=/n/groups/walsh/indData/elain/DeepWES4_7
interval=/n/groups/walsh/indData/elain/DeepWES4_7/S33266340_hs_hg19/S33266340_Regions.nochr.bed # exome targeted regions
tmp_dir=$folder/tmp
mkdir -p $tmp_dir
mkdir -p $tmp_dir/raw_bams
mkdir -p $tmp_dir/markdup
mkdir -p $tmp_dir/fixtags
mkdir -p $tmp_dir/BR
mkdir -p $folder/final

sample_id_list=./sample_id.txt

ENV0="-p medium -t 1-00:00 -c 1 --mem=1G --mail-type=END,FAIL --mail-user=yilanwang@g.harvard.edu"
ENV1="-p medium -t 1-00:00 -c 12 --mem=10G --mail-type=END,FAIL --mail-user=yilanwang@g.harvard.edu"
ENV2="-p medium -t 1-00:00 -c 1 --mem=5G --mail-type=END,FAIL --mail-user=yilanwang@g.harvard.edu"
ENV3="-p short -t 0-12:00 -c 1 --mem=32G --mail-type=END,FAIL --mail-user=yilanwang@g.harvard.edu"
ENV4="-p short -t 0-12:00 -c 1 --mem=16G --mail-type=END,FAIL --mail-user=yilanwang@g.harvard.edu"
ENV5="-p short -t 0-12:00 -c 4 --mem=8G --mail-type=END,FAIL --mail-user=yilanwang@g.harvard.edu"
ENV6="-p medium -t 5-00:00 -c 1 --mem=8G --mail-type=END,FAIL --mail-user=yilanwang@g.harvard.edu"
ENV7="-p short -t 0-12:00 -c 1 --mem=8G --mail-type=END,FAIL --mail-user=yilanwang@g.harvard.edu"

while read LINE; do
	prefix=$LINE
	fq1=$folder/$prefix/${prefix}_1.fastq.gz
	fq2=$folder/$prefix/${prefix}_2.fastq.gz
	FQ1=$folder/$prefix/${prefix}_1.fq.gz
	FQ2=$folder/$prefix/${prefix}_2.fq.gz
	jobid00=$(sbatch -J ${prefix}_preprocess_fq1 $ENV0 -o logs/${prefix}_preprocess_fq1.log preprocess_fq.sh $fq1 $FQ1)
	jobid01=$(sbatch -J ${prefix}_preprocess_fq2 $ENV0 -o logs/${prefix}_preprocess_fq2.log preprocess_fq.sh $fq2 $FQ2)
	jobid1=$(sbatch -J ${prefix}_bwa $ENV1 -o logs/${prefix}_bwa.log bwa_mem.sh $prefix $FQ1 $FQ2 $tmp_dir/raw_bams)
	jobid1=$(echo $jobid1 | tr -dc '0-9')
	echo $jobid1
	
	jobid2=$(sbatch --dependency=afterok:$jobid1 -J ${prefix}_sort $ENV2 -o logs/${prefix}_sort.log gatk4_sort.sh $tmp_dir/raw_bams $prefix $tmp_dir/markdup)
	jobid2=$(echo $jobid2 | tr -dc '0-9')
	echo $jobid2

	jobid3=$(sbatch --dependency=afterok:$jobid2 -J ${prefix}_markdup $ENV3 -o logs/${prefix}_markdup.log picard_markdup.sh $tmp_dir/raw_bams $prefix $tmp_dir/markdup)
	jobid3=$(echo $jobid3 | tr -dc '0-9')
	echo $jobid3
	
	jobid4=$(sbatch --dependency=afterok:$jobid3 -J ${prefix}_fixtags $ENV4 -o logs/${prefix}_fixtags.log GATK4_FixTags.sh $tmp_dir/markdup $prefix $tmp_dir/fixtags)
	jobid4=$(echo $jobid4 | tr -dc '0-9')
	echo $jobid4
	
	jobid5=$(sbatch --dependency=afterok:$jobid4 -J ${prefix}_RTC $ENV5 -o logs/${prefix}_RTC.log GATK3_RTC.sh $tmp_dir/fixtags $prefix $interval)
	jobid5=$(echo $jobid5 | tr -dc '0-9')
	echo $jobid5
	
	#if [ $prefix == "0873_H" ]; then
		#echo $prefix
	jobid6=$(sbatch --dependency=afterok:$jobid5 -J ${prefix}_IR $ENV6 -o logs/${prefix}_IR.log GATK3_IR_nWay.sh $tmp_dir/fixtags $prefix $interval)
	jobid6=$(sbatch -J ${prefix}_IR $ENV6 -o logs/${prefix}_IR.log GATK3_IR_nWay.sh $tmp_dir/fixtags $prefix $interval)
	jobid6=$(echo $jobid6 | tr -dc '0-9')
	echo $jobid6
		
	jobid7=$(sbatch --dependency=afterok:$jobid6 -J ${prefix}_BR $ENV7 -o logs/${prefix}_BR.log GATK4_BR.sh $tmp_dir/fixtags $prefix $interval $tmp_dir/BR)
	jobid7=$(echo $jobid7 | tr -dc '0-9')
	echo $jobid7
		
	jobid8=$(sbatch --dependency=afterok:$jobid7 -J ${prefix}_BQSR $ENV4 -o logs/${prefix}_BQSR.log GATK4_BQSR.sh $tmp_dir/fixtags $prefix $interval $folder/final)
	echo $jobid8
	#fi
done < $sample_id_list
