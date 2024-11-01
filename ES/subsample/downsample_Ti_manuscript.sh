#!/bin/bash
# approach 2
module load gcc/6.2.0 picard/2.27.5
# for approach 1
module load bedtools/2.27.1 python/3.7.4

bed_int=../preprocessing/S33266340_Regions.nochr.bed

DOWNSAMPLE() {
	while read LINE; do
		IFS=, read outprefix in_bam fraction <<< $LINE
		outdir="picard_bams"
		mkdir -p $outdir
		bamname=$(basename $in_bam)
		outbam=$outdir/$bamname

		echo $outprefix
		# echo $fraction
		nt=0-01:00

		# two approaches, either works, choose one

		# approach 1: using mosdepth
		mkdir -p mosdepth_picard/$outprefix
		sbatch -N 1 -c 4 --mem 3G -J ${outprefix}_mosdepth_cov -t $nt -p priority -o mosdepth_picard/$outprefix/downsampled_picard_coverage.log --mail-user=yilanwang@g.harvard.edu --mail-type=FAIL,END --wrap="mosdepth -t 4 -b $bed_int mosdepth_picard/$outprefix/subsampled $outbam;\
			gzip -df mosdepth_picard/$outprefix/subsampled.per-base.bed.gz;\
			bash calc_avg_cov.sh mosdepth_picard/$outprefix/subsampled $bed_int"

		# approach 2: using picard
		mkdir -p picard/$outprefix
		sbatch -N 1 -c 4 --mem 3G -J ${outprefix}_downsample -t $nt -p short -o picard/$outprefix/downsampled_picard.log --mail-user=... --mail-type=FAIL,END --wrap="java -jar $PICARD/picard.jar DownsampleSam I=$in_bam O=$outbam P=$fraction" # picard takes an hour
		mkdir -p picard_bams
		sbatch -J ${outprefix}_bedtools_cov -N 1 -c 1 --mem=3G -t 0-1:00 -p priority -o picard_bams/${outprefix}_bedtools_cov.log --mail-user=... --mail-type=FAIL,END calc_avg_cov_bedtools.sh $outdir $outprefix $bed_int
	done < subsample_fraction.txt
}

CHECK_DEPTH() {
	output=subsampled_depth_picard.txt
	printf "" > $output

	while read LINE; do
		IFS=, read outprefix in_bam fraction <<< $LINE
		if [ -f picard_bams/$outprefix.coverage ]; then
			printf "picard_bams/$outprefix\t" >> $output
			tail -n 1 picard_bams/$outprefix.coverage >> $output
			printf "\n" >> $output
		else
			echo "picard_bams/$outprefix doesn't exist!!!"
		fi
	done < subsample_fraction.txt
}

DOWNSAMPLE
CHECK_DEPTH