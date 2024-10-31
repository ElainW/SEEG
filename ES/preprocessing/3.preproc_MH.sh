#!/bin/bash
module load gcc/6.2.0 java/jdk-1.8u112 bwa/0.7.15 samtools/0.1.19 bedtools/2.27.1 blat/35
sample_id_list=./sample_id.txt
folder=/n/groups/walsh/indData/elain/DeepWES4_7
interval=/n/groups/walsh/indData/elain/DeepWES4_7/S33266340_hs_hg19/S33266340_Regions.nochr.bed
mkdir -p $folder/HC
mkdir -p $folder/MH
mkdir -p $folder/MH_2step_params
mkdir -p $folder/MH_2step_out

# while read LINE; do
# 	IFS=, read prefix sex <<< $LINE
# 	sbatch -p medium -t 1-00:00 -c 1 -J ${prefix}_HC_MH -o logs/${prefix}_MH_step2.log --mem=64G --mail-type=END,FAIL --mail-user=yilanwang@g.harvard.edu gatk3_HC.sh $folder/final/ $prefix $interval $folder/HC $folder/MH_2step_params $folder/MH_2step_out $sex
# 	#if [ $prefix = "0873_H" ]; then
# 	# test on 0859_A took 19.5h + 9.5h MH
# 	sbatch -p medium -t 3-0:00 -c 1 -J ${prefix}_HC_MH -o logs/${prefix}_HC_MH_4th_trial.log --mem=64G --mail-type=END,FAIL --mail-user=yilanwang@g.harvard.edu gatk3_HC.sh $folder/final/ $prefix $interval $folder/HC $folder/MH_2step_params $folder/MH_2step_out
# 	#fi
# done < test_sample_id.txt

# rerun the Ti samples after subsampling to the average depth of amplified samples (only for statistical comparisons)
# change the input folder to where the subsampled bams are
# change the output to subsampled output (do not want to mess with the original calls, since this is only for calculating stats)
while read LINE; do
	IFS=, read prefix sex <<< $LINE
	# use the same indel region filter bed
	# generate a different set of parameters		
	# can technically run two steps at once if I do stdout to the epilepsy.properties file in the first step and use that in -C for the second step
	# sbatch -p priority -t 1-0:00 -c 1 -J ${prefix}_HC_MH -o logs/subsampled_${prefix}_HC_MH.log --mem=64G --mail-type=END,FAIL --mail-user=yilanwang@g.harvard.edu gatk3_HC_Ti_subsampled.sh /n/groups/walsh/indData/elain/scripts/WES/subsample/picard_bams $prefix $interval $folder/HC $folder/MH_2step_params $folder/MH_2step_out $sex
	#fi
	sbatch -p priority -t 1-0:00 -c 1 -J ${prefix}_HC_MH -o logs/subsampled_${prefix}_HC_MH_step2.log --mem=64G --mail-type=END,FAIL --mail-user=yilanwang@g.harvard.edu gatk3_HC_Ti_subsampled.sh /n/groups/walsh/indData/elain/scripts/WES/subsample/picard_bams $prefix $interval $folder/HC $folder/MH_2step_params $folder/MH_2step_out $sex
done < Ti_sample_id.txt