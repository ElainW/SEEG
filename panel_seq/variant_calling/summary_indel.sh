#!/bin/bash
#SBATCH -p priority
#SBATCH -t 0-01:00
#SBATCH --mem=3G
#SBATCH -c 1
#SBATCH -N 1
#SBATCH --mail-user=yilanwang@g.harvard.edu
#SBATCH --mail-type=FAIL,END
REFERENCE_DIR=/home/yh174/reference
TOOLS_DIR=/home/yh174/tools
TEMP_DIR=/home/yw222/temp
ROOT=/n/groups/walsh/indData/elain
SCRIPT_DIR=$ROOT/scripts
#INPUT_DIR=/n/data1/bch/genetics/lee/August/AD_clonal/cancer_panel
INPUT_DIR=$SCRIPT_DIR/panel_seq_input
FASTQ_DIR=$ROOT/TargetedPanelwithWes
OUTPUT_DIR=$ROOT/panel_seq_output
export PATH="$TOOLS_DIR/:$SCRIPT_DIR/:$TOOLS_DIR/Pisces-5.3/:$PATH"
cd $OUTPUT_DIR

SUMMARY_INDEL ()
{
	# count the number of MH calls present in controls
	# $INPUT_DIR/FCDHME-122021-2_1_case_control.csv indicates cases and controls in 5th column (1: hot electrode [case], 2: cold electrode [case], 3: bulk brain [case], 4: blood [control])
	# file format: chr pos count_in_controls
	# for case, make sure the entry isn't present in any of the controls
	# now remove variants with VAF<0.01
	awk -F"," '$5==1||$5==2||$5==3' $INPUT_DIR/FCDHME-122021-2_1_case_control.csv | cut -d "," -f1 | while read f; do grep PASS Pisces/$f.final.vcf | awk '$10~"0/1"' | awk 'length($4)>1||length($5)>1' | awk '{split($10,a,":");split(a[3],b,",");if(b[2]>3&&a[5]<0.3&&a[5]>=0.01){print $0}}' | cut -f1,2 | while read f1 f2; do echo $f1; echo $f2; awk -F"," '$5==4' $INPUT_DIR/FCDHME-122021-2_1_case_control.csv | cut -d ',' -f1 | while read f3; do awk 'length($4)>1||length($5)>1' Pisces/$f3.final.vcf; done | awk -v chr=$f1 -v pos=$f2 '$1==chr&&$2==pos' | wc -l; done | paste - - - > Pisces/$f.raw.check; done
	# for control, make sure the entry isn't present in any of the other controls
	awk -F"," '$5==4' $INPUT_DIR/FCDHME-122021-2_1_case_control.csv | cut -d "," -f1 | while read f; do grep PASS Pisces/$f.final.vcf | awk '$10~"0/1"' | awk 'length($4)>1||length($5)>1' | awk '{split($10,a,":");split(a[3],b,",");if(b[2]>3&&a[5]<0.3){print $0}}' | cut -f1,2 | while read f1 f2; do echo $f1; echo $f2; awk -F"," -v sample=$f '$5==4&&$1!=sample' $INPUT_DIR/FCDHME-122021-2_1_case_control.csv | cut -d ',' -f1 | while read f3; do awk 'length($4)>1||length($5)>1' Pisces/$f3.final.vcf; done | awk -v chr=$f1 -v pos=$f2 '$1==chr&&$2==pos' | wc -l; done | paste - - - > Pisces/$f.raw.check; done
	
	# filter out calls present in controls (or other controls)
	cut -d "," -f1 $INPUT_DIR/FCDHME-122021-2_1_case_control.csv | while read f; do awk -F"\t" '{if ($3==0){OFS="\t"; print $1,$2}}' Pisces/$f.raw.check > Pisces/$f.filtered.tsv; done
	
	# get the entire entry from MH and then convert to vcf (VF=VAF)
	cut -d "," -f1 $INPUT_DIR/FCDHME-122021-2_1_case_control.csv | while read f; do cat Pisces/header.txt > Pisces/$f.P.final.vcf; printf "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t$f\n" >> Pisces/$f.P.final.vcf; myjoin -m -F1,2 Pisces/$f.filtered.tsv -f1,2 Pisces/$f.final.vcf | sed 's/^/chr/' | cut --complement -f2,3 >> Pisces/$f.P.final.vcf; bgzip -f Pisces/$f.P.final.vcf; bcftools index Pisces/$f.P.final.vcf.gz; done
}

# SUMMARY_INDEL

SUMMARY_INDEL_XI2 ()
{
	# count the number of MH calls present in controls
	# $INPUT_DIR/FCDHME-122021-2_1_case_control.csv indicates cases and controls in 5th column (1: hot electrode [case], 2: cold electrode [case], 3: bulk brain [case], 4: blood [control])
	# file format: chr pos count_in_controls
	# for case, make sure the entry isn't present in any of the controls
	# now remove variants with VAF<0.01
	awk -F"," '$5==1||$5==2||$5==3' $INPUT_DIR/FCDHME-122021-2_1_case_control.csv | cut -d "," -f1 | while read f; do grep PASS Pisces_XI2/$f.final.vcf | awk '$10~"0/1"' | awk 'length($4)>1||length($5)>1' | awk '{split($10,a,":");split(a[3],b,",");if(b[2]>3&&a[5]<0.3&&a[5]>=0.01){print $0}}' | cut -f1,2 | while read f1 f2; do echo $f1; echo $f2; awk -F"," '$5==4' $INPUT_DIR/FCDHME-122021-2_1_case_control.csv | cut -d ',' -f1 | while read f3; do awk 'length($4)>1||length($5)>1' Pisces_XI2/$f3.final.vcf; done | awk -v chr=$f1 -v pos=$f2 '$1==chr&&$2==pos' | wc -l; done | paste - - - > Pisces_XI2/$f.raw.check; done
	# for control, make sure the entry isn't present in any of the other controls
	awk -F"," '$5==4' $INPUT_DIR/FCDHME-122021-2_1_case_control.csv | cut -d "," -f1 | while read f; do grep PASS Pisces_XI2/$f.final.vcf | awk '$10~"0/1"' | awk 'length($4)>1||length($5)>1' | awk '{split($10,a,":");split(a[3],b,",");if(b[2]>3&&a[5]<0.3){print $0}}' | cut -f1,2 | while read f1 f2; do echo $f1; echo $f2; awk -F"," -v sample=$f '$5==4&&$1!=sample' $INPUT_DIR/FCDHME-122021-2_1_case_control.csv | cut -d ',' -f1 | while read f3; do awk 'length($4)>1||length($5)>1' Pisces_XI2/$f3.final.vcf; done | awk -v chr=$f1 -v pos=$f2 '$1==chr&&$2==pos' | wc -l; done | paste - - - > Pisces_XI2/$f.raw.check; done
	
	# filter out calls present in controls (or other controls)
	cut -d "," -f1 $INPUT_DIR/FCDHME-122021-2_1_case_control.csv | while read f; do awk -F"\t" '{if ($3==0){OFS="\t"; print $1,$2}}' Pisces_XI2/$f.raw.check > Pisces_XI2/$f.filtered.tsv; done
	
	# get the entire entry from MH and then convert to vcf (VF=VAF)
	cut -d "," -f1 $INPUT_DIR/FCDHME-122021-2_1_case_control.csv | while read f; do cat Pisces_XI2/header.txt > Pisces_XI2/$f.P.final.vcf; printf "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t$f\n" >> Pisces_XI2/$f.P.final.vcf; myjoin -m -F1,2 Pisces_XI2/$f.filtered.tsv -f1,2 Pisces_XI2/$f.final.vcf | sed 's/^/chr/' | cut --complement -f2,3 >> Pisces_XI2/$f.P.final.vcf; bgzip -f Pisces_XI2/$f.P.final.vcf; bcftools index Pisces_XI2/$f.P.final.vcf.gz; done
}
SUMMARY_INDEL_XI2