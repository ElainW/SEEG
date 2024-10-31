#!/bin/bash
module load gcc/6.2.0 python/3.7.4
source ~/yw222PythonFolder/python_bam/bin/activate

#cd ../panel_seq_output/stats
#filelist=("coverage_summary" "MH_filtered_count.final" "Pisces_filtered_count.final")
#for f in ${filelist[@]}; do for i in {1..4}; do awk -F"\t" -v num=$i '$3==num' $f.tsv | cut -f1,2 > ${i}_$f.tsv; done; done
#
#for i in {1..4}; do
#	for j in {1..4}; do
#		if [ $i -lt $j ]; then
#			echo $i $j
#			for f in ${filelist[@]}; do
#				echo $f
#				python3 /n/groups/walsh/indData/elain/scripts/stats/stats.py ${i}_$f.tsv ${j}_$f.tsv $i $j
#			done
#		fi
#	done
#done

#filelist=("coverage/hot_electrode_bamlist_single_depth.txt" "coverage/cold_electrode_bamlist_single_depth.txt" "coverage/bulk_brain_bamlist_single_depth.txt" "coverage/blood_bamlist_single_depth.txt")
#for i in {0..3}; do cut -f1,2 ${filelist[i]} > ${i}_avg_cov.tsv; done
#for i in {0..3}; do
#	for j in {0..3}; do
#		if [ $i -lt $j ]; then
#			echo $i $j
#			python3 /n/groups/walsh/indData/elain/scripts/stats/stats.py ${i}_avg_cov.tsv ${j}_avg_cov.tsv $i $j
#		fi
#	done
#done

#filelist=("VAF/MH_vaf_complete.tsv" "VAF/MH_pathogenic_vaf_complete.tsv" "VAF/Pisces_vaf_complete.tsv" "VAF/Pisces_pathogenic_vaf_complete.tsv")
#for file in ${filelist[@]}; do
#	fname=$(basename $file)
#	caller=$(echo $fname | awk -F"_" '{print $1}')
#	if [[ $fname == *"pathogenic"* ]]; then
#		grep "hot electrode" $file | cut -f1,2 > 1_${caller}_pathogenic_vaf.tsv
#		grep "cold electrode" $file | cut -f1,2 > 2_${caller}_pathogenic_vaf.tsv
#		grep "bulk brain" $file | cut -f1,2 > 3_${caller}_pathogenic_vaf.tsv
#		grep "blood" $file | cut -f1,2 > 4_${caller}_pathogenic_vaf.tsv
#	else
#		grep "hot electrode" $file | cut -f1,2 > 1_${caller}_vaf.tsv
#		grep "cold electrode" $file | cut -f1,2 > 2_${caller}_vaf.tsv
#		grep "bulk brain" $file | cut -f1,2 > 3_${caller}_vaf.tsv
#		grep "blood" $file | cut -f1,2 > 4_${caller}_vaf.tsv
#	fi
#done
#
#caller_list=("MH" "Pisces")
#for i in {1..4}; do
#	for j in {1..4}; do
#		if [ $i -lt $j ]; then
#			echo $i $j
#			for caller in ${caller_list[@]}; do
#				echo $caller
#				python3 /n/groups/walsh/indData/elain/scripts/stats/stats.py ${i}_${caller}_vaf.tsv ${j}_${caller}_vaf.tsv $i $j
#				echo "pathogenic"
#				python3 /n/groups/walsh/indData/elain/scripts/stats/stats.py ${i}_${caller}_pathogenic_vaf.tsv ${j}_${caller}_pathogenic_vaf.tsv $i $j
#			done
#		fi
#	done
#done

#filelist=("pathogenic_count/filtered_MH_count_complete.tsv" "pathogenic_count/filtered_Pisces_count_complete.tsv")
#for file in ${filelist[@]}; do
#	fname=$(basename $file)
#	caller=$(echo $fname | awk -F"_" '{print $2}')
#	if [[ $fname == *"pathogenic"* ]]; then
#		grep "hot electrode" $file | cut -f1,2 > 1_${caller}_pathogenic_count.tsv
#		grep "cold electrode" $file | cut -f1,2 > 2_${caller}_pathogenic_count.tsv
#		grep "bulk brain" $file | cut -f1,2 > 3_${caller}_pathogenic_count.tsv
#		grep "blood" $file | cut -f1,2 > 4_${caller}_pathogenic_count.tsv
#	else
#		grep "hot electrode" $file | cut -f1,2 > 1_${caller}_count.tsv
#		grep "cold electrode" $file | cut -f1,2 > 2_${caller}_count.tsv
#		grep "bulk brain" $file | cut -f1,2 > 3_${caller}_count.tsv
#		grep "blood" $file | cut -f1,2 > 4_${caller}_count.tsv
#	fi
#done
#
#caller_list=("MH" "Pisces")
#for i in {1..4}; do
#	for j in {1..4}; do
#		if [ $i -lt $j ]; then
#			echo $i $j
#			for caller in ${caller_list[@]}; do
#				echo $caller
#				python3 /n/groups/walsh/indData/elain/scripts/stats/stats.py ${i}_${caller}_count.tsv ${j}_${caller}_count.tsv $i $j
#			done
#		fi
#	done
#done

filelist=("pathogenic_count/MH_pathogenic_count_complete.tsv" "pathogenic_count/Pisces_pathogenic_count_complete.tsv")
for file in ${filelist[@]}; do
	fname=$(basename $file)
	caller=$(echo $fname | awk -F"_" '{print $1}')
	if [[ $fname == *"pathogenic"* ]]; then
		grep "hot electrode" $file | cut -f1,2 > 1_${caller}_pathogenic_count.tsv
		grep "cold electrode" $file | cut -f1,2 > 2_${caller}_pathogenic_count.tsv
		grep "bulk brain" $file | cut -f1,2 > 3_${caller}_pathogenic_count.tsv
		grep "blood" $file | cut -f1,2 > 4_${caller}_pathogenic_count.tsv
	else
		grep "hot electrode" $file | cut -f1,2 > 1_${caller}_count.tsv
		grep "cold electrode" $file | cut -f1,2 > 2_${caller}_count.tsv
		grep "bulk brain" $file | cut -f1,2 > 3_${caller}_count.tsv
		grep "blood" $file | cut -f1,2 > 4_${caller}_count.tsv
	fi
done

caller_list=("MH" "Pisces")
for i in {1..4}; do
	for j in {1..4}; do
		if [ $i -lt $j ]; then
			echo $i $j
			for caller in ${caller_list[@]}; do
				echo $caller
				python3 /n/groups/walsh/indData/elain/scripts/stats/stats.py ${i}_${caller}_pathogenic_count.tsv ${j}_${caller}_pathogenic_count.tsv $i $j
			done
		fi
	done
done
