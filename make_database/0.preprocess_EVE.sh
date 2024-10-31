#!/bin/bash
#SBATCH -J gen_eve_vcf
#SBATCH -N 1
#SBATCH -c 1
#SBATCH -o gen_eve_vcf.log
#SBATCH --mem 5G
#SBATCH -t 0-00:30
#SBATCH -p short
#SBATCH --mail-user=yilanwang@g.harvard.edu
#SBATCH --mail-type=FAIL,END

module load gcc/6.2.0 python/3.7.4 bcftools/1.13
# convert all the files in vcf_files_missense_mutations into SNPs for those with 1 nucleotide change (ignoring multiple nucleotide changes for now), also update the coordinate if the nucleotide change happens in the 2nd or 3rd nucleotide in the codon
IN_DIR=/n/groups/walsh/indData/Sattar/WES/KMTS/variant_prioritization/databases/vcf_files_missense_mutations
OUT_DIR=/n/groups/walsh/indData/Sattar/WES/KMTS/variant_prioritization/databases/vcf_files_missense_mutations_snp
mkdir -p $OUT_DIR
OUT_TMP=/n/groups/walsh/indData/Sattar/WES/KMTS/variant_prioritization/databases/EVE_SNP_all.tmp
OUT_FILE=/n/groups/walsh/indData/Sattar/WES/KMTS/variant_prioritization/databases/EVE_SNP_all.vcf
#printf "##fileformat=VCFv4.2\n##fileDate=20220116\n##source=EVEmodel\n##reference=GRCh38\n##phasing=none\n##INFO=<ID=EVE,Number=1,Type=Float,Description=\"Score from EVE model\">\n##INFO=<ID=EnsTranscript,Number=1,Type=String,Description=\"Pipe-separated list of Ensembl transcript IDs for this protein genomic position\">\n##INFO=<ID=RevStr,Number=1,Type=String,Description=\"Boolean for whether protein is coded on reverse/negative strand (True) or not (False)\">\n##INFO=<ID=ProtMut,Number=1,Type=String,Description=\"String formatted as: [UNIPROT_ACCESSION_NUMBER]_[WILDTYPE_AA][AA_POSITION][VARIANT_AA]\">\n##INFO=<ID=Class10,Number=1,Type=String,Description=\"Classification (Benign, Uncertain, or Pathogenic) when setting 10% as uncertain\">\n##INFO=<ID=Class20,Number=1,Type=String,Description=\"Classification (Benign, Uncertain, or Pathogenic) when setting 20% as uncertain\">\n##INFO=<ID=Class25,Number=1,Type=String,Description=\"Classification (Benign, Uncertain, or Pathogenic) when setting 25% as uncertain\">\n##INFO=<ID=Class30,Number=1,Type=String,Description=\"Classification (Benign, Uncertain, or Pathogenic) when setting 30% as uncertain\">\n##INFO=<ID=Class40,Number=1,Type=String,Description=\"Classification (Benign, Uncertain, or Pathogenic) when setting 40% as uncertain\">\n##INFO=<ID=Class50,Number=1,Type=String,Description=\"Classification (Benign, Uncertain, or Pathogenic) when setting 50% as uncertain\">\n##INFO=<ID=Class60,Number=1,Type=String,Description=\"Classification (Benign, Uncertain, or Pathogenic) when setting 60% as uncertain\">\n##INFO=<ID=Class70,Number=1,Type=String,Description=\"Classification (Benign, Uncertain, or Pathogenic) when setting 70% as uncertain\">\n##INFO=<ID=Class75,Number=1,Type=String,Description=\"Classification (Benign, Uncertain, or Pathogenic) when setting 75% as uncertain\">\n##INFO=<ID=Class80,Number=1,Type=String,Description=\"Classification (Benign, Uncertain, or Pathogenic) when setting 80% as uncertain\">\n##INFO=<ID=Class90,Number=1,Type=String,Description=\"Classification (Benign, Uncertain, or Pathogenic) when setting 90% as uncertain\">\n" > $OUT_TMP
#grep "^##contig" /n/groups/walsh/indData/Sattar/GATK/reference/Homo_sapiens_assembly38.dbsnp138.vcf >> $OUT_TMP
#printf "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n" >> $OUT_TMP
#
#for f in $IN_DIR/*.vcf; do
#	f_name=$(basename $f)
#	#python3 preprocess_EVE.py $f $OUT_DIR/$f_name
#	grep -v "^#" $OUT_DIR/$f_name >> $OUT_TMP
#done

grep -v "^chrCHR" $OUT_TMP | grep -v "^chrGL000194.1" > $OUT_TMP.tmp
bcftools sort $OUT_TMP.tmp -m 1G -O v > $OUT_FILE
bgzip -c $OUT_FILE > $OUT_FILE.gz
tabix $OUT_FILE.gz