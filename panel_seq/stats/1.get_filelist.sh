#OUTPUT_LIST=("hot_electrode_bamlist.txt" "cold_electrode_bamlist.txt" "bulk_brain_bamlist.txt" "blood_bamlist.txt")
#for output in ${OUTPUT_LIST[@]}; do
#	printf "" > $output
#done
#
#ROOT=/n/groups/walsh/indData/elain
#INPUT_DIR=$ROOT/scripts/panel_seq_input
BAM_DIR=$ROOT/panel_seq_output/finalBam
#for i in {0..3}; do
#	awk -F"," -v i=$((i+1)) '$5==i' $INPUT_DIR/FCDHME-122021-2_1_case_control.csv | cut -d "," -f1 | while read f; do printf "$f,$BAM_DIR/$f.final.bam\n" >> ${OUTPUT_LIST[i]}; done
#done

# get raw sequencing depth
#OUTPUT_LIST=("hot_electrode_bamlist_raw.txt" "cold_electrode_bamlist_raw.txt" "bulk_brain_bamlist_raw.txt" "blood_bamlist_raw.txt")
#for output in ${OUTPUT_LIST[@]}; do
#	printf "" > $output
#done
#
ROOT=/n/groups/walsh/indData/elain
INPUT_DIR=$ROOT/scripts/panel_seq_input
#BAM_DIR=$ROOT/panel_seq_output/bam
#for i in {0..3}; do
#	awk -F"," -v i=$((i+1)) '$5==i' $INPUT_DIR/FCDHME-122021-2_1_case_control.csv | cut -d "," -f1 | while read f; do printf "$f,$BAM_DIR/$f.sorted.bam\n" >> ${OUTPUT_LIST[i]}; done
#done

# get sequencing depth after locatit and sort
#OUTPUT_LIST=("hot_electrode_bamlist_locatit.txt" "cold_electrode_bamlist_locatit.txt" "bulk_brain_bamlist_locatit.txt" "blood_bamlist_locatit.txt")
#for output in ${OUTPUT_LIST[@]}; do
#	printf "" > $output
#done
#
#for i in {0..3}; do
#	awk -F"," -v i=$((i+1)) '$5==i' $INPUT_DIR/FCDHME-122021-2_1_case_control.csv | cut -d "," -f1 | while read f; do printf "$f,$BAM_DIR/$f.masked.realigned.bam\n" >> ${OUTPUT_LIST[i]}; done
#done

# get the final sequencing depth after removing PCR duplicates based on UMI (locatit single mode)
BAM_DIR=$ROOT/panel_seq_output/finalBam
OUTPUT_LIST=("hot_electrode_bamlist_single.txt" "cold_electrode_bamlist_single.txt" "bulk_brain_bamlist_single.txt" "blood_bamlist_single.txt")
for output in ${OUTPUT_LIST[@]}; do
	printf "" > $output
done

for i in {0..3}; do
	awk -F"," -v i=$((i+1)) '$5==i' $INPUT_DIR/FCDHME-122021-2_1_case_control.csv | cut -d "," -f1 | while read f; do printf "$f,$BAM_DIR/$f.final.bam\n" >> ${OUTPUT_LIST[i]}; done
done
