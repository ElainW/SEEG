#!/bin/bash
#SBATCH -p priority
#SBATCH -t 0-01:00
#SBATCH --mem=3G
#SBATCH -c 1
#SBATCH -N 1
#SBATCH --mail-user=...
#SBATCH --mail-type=FAIL,END

module load gcc/6.2.0 python/3.7.4 bcftools/1.13
REFERENCE_DIR=...
TOOLS_DIR=../../tools
TEMP_DIR=...
ROOT=...
SCRIPT_DIR=./
INPUT_DIR=../panel_seq_input
FASTQ_DIR=...
OUTPUT_DIR=$ROOT/panel_seq_output
export PATH="$TOOLS_DIR/:$SCRIPT_DIR/:$TOOLS_DIR/Pisces-5.3/:$PATH"
cd $OUTPUT_DIR

SUMMARY ()
{
	# summarize the sample coverage
	cat $INPUT_DIR/barcode_id.txt | while read f; do echo $f; cat finalBam/$f.final.coverageBed | awk '$1=="all"' | awk '{sum+=$2*$5}END{print sum}'; cat finalBam/$f.final.coverageBed | awk '$1=="all"' | awk '{if($2>500){sum+=$5}}END{print sum}'; done | paste - - - > FCDHME-122021-2_1.coverage.summary
	
	# filter out low-confidence variants (now taking out those with <1% VAF)
	cat $INPUT_DIR/barcode_id.txt | while read f; do awk -F"\t" '$7>3&&$7/($6+$7+$8)<0.3&&$7/($6+$7+$8)>=0.01&&10^$12>0.5' MosaicHunter/$f.MH.tsv > MosaicHunter/$f.MH.raw_filtered.tsv; done
	# count the number of MH calls present in controls
	# $INPUT_DIR/FCDHME-122021-2_1_case_control.csv indicates cases and controls in 5th column (1: hot electrode [case], 2: cold electrode [case], 3: bulk brain [case], 4: blood [control])
	# file format: chr pos count_in_controls
	# for case, make sure the entry isn't present in any of the controls
	awk -F"," '$5==1||$5==2||$5==3' $INPUT_DIR/FCDHME-122021-2_1_case_control.csv | cut -d "," -f1 | while read f; do cut -f1,2 MosaicHunter/$f.MH.raw_filtered.tsv | while read f1 f2; do echo $f1; echo $f2; awk -F"," '$5==4' $INPUT_DIR/FCDHME-122021-2_1_case_control.csv | cut -d ',' -f1 | while read f3; do cat MosaicHunter/$f3.MH.raw_filtered.tsv; done | awk -v chr=$f1 -v pos=$f2 '$1==chr&&$2==pos' | wc -l; done | paste - - - > MosaicHunter/$f.raw.check; done
	# for control, make sure the entry isn't present in any of the other controls
	awk -F"," '$5==4' $INPUT_DIR/FCDHME-122021-2_1_case_control.csv | cut -d "," -f1 | while read f; do cut -f1,2 MosaicHunter/$f.MH.raw_filtered.tsv | while read f1 f2; do echo $f1; echo $f2; awk -F"," -v sample=$f '$5==4&&$1!=sample' $INPUT_DIR/FCDHME-122021-2_1_case_control.csv | cut -d "," -f1 | while read f3; do cat MosaicHunter/$f3.MH.raw_filtered.tsv; done | awk -v chr=$f1 -v pos=$f2 '$1==chr&&$2==pos' | wc -l; done | paste - - - > MosaicHunter/$f.raw.check; done
	
	# filter out calls present in controls (or other controls)
	cut -d "," -f1 $INPUT_DIR/FCDHME-122021-2_1_case_control.csv | while read f; do awk -F"\t" '{if ($3==0){OFS="\t"; print $1,$2}}' MosaicHunter/$f.raw.check > MosaicHunter/$f.filtered.tsv; done
	
	# get the entire entry from MH and then convert to vcf
	cut -d "," -f1 $INPUT_DIR/FCDHME-122021-2_1_case_control.csv | while read f; do myjoin -m -F1,2 MosaicHunter/$f.filtered.tsv -f1,2 MosaicHunter/$f.MH.tsv | sed 's/^/chr/' | cut --complement -f2,3 > MosaicHunter/$f.MH.final.tsv; python3 $SCRIPT_DIR/MH_tsv_to_vcf.py MosaicHunter/$f.MH.final.tsv MosaicHunter/$f.MH.final.vcf $f; bgzip -f MosaicHunter/$f.MH.final.vcf; bcftools index MosaicHunter/$f.MH.final.vcf.gz; done
}

SUMMARY