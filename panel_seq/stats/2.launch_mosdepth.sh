module load gcc/6.2.0 conda2
source activate mosdepth

bed_int=../panel_seq_input/FCDHME-122021-2_1_Covered.b37.bed
CALC_DEPTH() {
	input=$1
	prefix=$2
	outdir=${input%.txt}
	mkdir -p $outdir
	while read LINE; do
		IFS=, read outprefix in_bam <<< $LINE
		#if grep -q "CANCELLED" $outdir/$outprefix/final_mosdepth.log; then
		echo $outdir/$outprefix
		mkdir -p $outdir/$outprefix
		if [ -f $outdir/$outprefix/$prefix.per-base.bed ]; then
			rm $outdir/$outprefix/$prefix.per-base.bed
		fi
		sbatch -N 1 -c 4 --mem 3G -J ${outdir}_$outprefix -t $3 -p short -o $outdir/$outprefix/${prefix}_mosdepth.log --mail-user=... --mail-type=FAIL,END --wrap="mosdepth -t 4 -b $bed_int $outdir/$outprefix/$prefix $in_bam; \
															gzip -d $outdir/$outprefix/$prefix.per-base.bed.gz; \
															bash calc_avg_cov.sh $outdir/$outprefix/$prefix $bed_int"
		#fi
	done < $input
}

CALC_DEPTH_RE() {
	input=$1
	prefix=$2
	outdir=${input%.txt}
	mkdir -p $outdir
	while read LINE; do
		IFS=, read outprefix in_bam <<< $LINE
		echo $outdir/$outprefix
		mkdir -p $outdir/$outprefix
		if [ -f $outdir/$outprefix/$prefix.per-base.bed ]; then
			rm $outdir/$outprefix/$prefix.per-base.bed
		fi
		sbatch -N 1 -c 4 --mem 3G -J ${outdir}_$outprefix -t $3 -p short -o $outdir/$outprefix/${prefix}_mosdepth.log --mail-user=... --mail-type=FAIL --wrap="mosdepth -t 4 -b $bed_int $outdir/$outprefix/$prefix $in_bam; \
														gzip -d $outdir/$outprefix/$prefix.per-base.bed.gz; \
														bash calc_avg_cov.sh $outdir/$outprefix/$prefix $bed_int"
	done < $input
}

GET_DEPTH() {
	input=$1
	prefix=$2
	outdir=${input%.txt}
	count_file=...
	printf "" > $count_file
	while read LINE; do
		IFS=, read outprefix in_bam <<< $LINE
		if [ -f $outdir/$outprefix/$prefix.per-base.bed ]; then
			rm $outdir/$outprefix/$prefix.counts $outdir/$outprefix/$prefix.mosdepth.global.dist.txt $outdir/$outprefix/$prefix.mosdepth.region.dist.txt $outdir/$outprefix/$prefix.mosdepth.summary.txt $outdir/$outprefix/$prefix.per-base.bed $outdir/$outprefix/$prefix.per-base.bed.gz.csi $outdir/$outprefix/$prefix.regions.bed.gz $outdir/$outprefix/$prefix.regions.bed.gz.csi
		fi
		printf "$outprefix\t" >> $count_file
		tail -n 1 $outdir/$outprefix/${prefix}_mosdepth.log >> $count_file
	done < $input
}

INPUT_LIST=("hot_electrode_bamlist.txt" "cold_electrode_bamlist.txt" "bulk_brain_bamlist.txt" "blood_bamlist.txt")
for input in ${INPUT_LIST[@]}; do
	CALC_DEPTH $input "final" 0-00:03
done

# wait till all jobs complete
for input in ${INPUT_LIST[@]}; do
	GET_DEPTH $input "final"
done

# get raw coverage
INPUT_LIST=("hot_electrode_bamlist_raw.txt" "cold_electrode_bamlist_raw.txt" "bulk_brain_bamlist_raw.txt" "blood_bamlist_raw.txt")
for input in ${INPUT_LIST[@]}; do
	CALC_DEPTH $input "raw" 0-00:05
done

wait till all jobs complete
for input in ${INPUT_LIST[@]}; do
	GET_DEPTH $input "raw"
done

# get coverage after locatit
#INPUT_LIST=("hot_electrode_bamlist_locatit.txt" "cold_electrode_bamlist_locatit.txt" "bulk_brain_bamlist_locatit.txt" "blood_bamlist_locatit.txt")
#for input in ${INPUT_LIST[@]}; do
#	CALC_DEPTH $input "locatit" 0-00:05
#done

# wait till all jobs complete
#for input in ${INPUT_LIST[@]}; do
#	GET_DEPTH $input "locatit"
#done

#CALC_DEPTH test_single_bamlist.txt "locatit_single" 0-00:02
#GET_DEPTH test_single_bamlist.txt "locatit_single"

# get coverage after locatit
#INPUT_LIST=("hot_electrode_bamlist_single.txt" "cold_electrode_bamlist_single.txt" "bulk_brain_bamlist_single.txt" "blood_bamlist_single.txt")
#for input in ${INPUT_LIST[@]}; do
#	CALC_DEPTH $input "single_final" 0-00:05
#done

# wait till all jobs complete
#for input in ${INPUT_LIST[@]}; do
#	GET_DEPTH $input "single_final"
#done
