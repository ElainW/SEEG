#!/bin/bash
#SBATCH -p priority
#SBATCH -t 0-00:05
#SBATCH -c 1
#SBATCH --mem=16G
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=yilanwang@g.harvard.edu

# 2022/03/22 updated the tags in af-only-gnomad to gnomAD_AF and gnomAD_AC
# 2022/06/06 this is a shorter version without gnomad and dbnsfp annotations (need to get hg19 version)
module load gcc/6.2.0 java vt
ROOT=/n/groups/walsh/indData/elain
DB_DIR=$ROOT/databases
file=$1
inputdir=$(dirname $file)
cd $inputdir

if [ -f $file.vcf ];then
	vt decompose -s -o $file.decompose.vcf $file.vcf
	vt normalize -r /home/yh174/reference/human_v37_contig_hg19_hs37d5/human_v37_contig_hg19_hs37d5.fasta -o $file.normalize.vcf $file.decompose.vcf


	#java -jar ~/snpEff/SnpSift.jar annotate /n/groups/walsh/indData/Sattar/GATK/reference/af-only-gnomad-reformat.hg38.vcf.gz -v $file.normalize.vcf > $file.normalize.gnomad.vcf

	java -Xmx16g -jar ~/snpEff/snpEff.jar -canon -ss 5 GRCh37.75 $file.normalize.vcf > $file.normalize.snpeff.vcf

	java -jar ~/snpEff/SnpSift.jar annotate $DB_DIR/clinvar_20220606.vcf.gz -v $file.normalize.snpeff.vcf > $file.normalize.snpeff.clinvar.vcf

	java -jar ~/snpEff/SnpSift.jar annotate /n/groups/walsh/indData/Sattar/GATK/reference/HGMD/hgmd_pro_2020.3_hg19.vcf -v $file.normalize.snpeff.clinvar.vcf > $file.normalize.snpeff.clinvar.hgmd.vcf

	#java -jar ~/snpEff/SnpSift.jar dbnsfp -v -db /n/groups/walsh/indData/Sattar/GATK/reference/dbNSFP4.1a.txt.gz $file.normalize.gnomad.snpeff.clinvar.hgmd.vcf > $file.normalize.gnomad.snpeff.clinvar.hgmd.dbNSFP4.vcf

	java -jar ~/snpEff/SnpSift.jar geneSets -v /n/groups/walsh/indData/Sattar/WES/code/GeneSets/Epilepsy_Seizure.gmt $file.normalize.snpeff.clinvar.hgmd.vcf > $file.normalize.snpeff.clinvar.hgmd.epilepsygeneset.vcf
	
	rm $file.normalize.vcf $file.decompose.vcf $file.normalize.snpeff.vcf $file.normalize.snpeff.clinvar.vcf $file.normalize.snpeff.clinvar.hgmd.vcf
else
	echo "The input file does not exist!"
fi                                     
