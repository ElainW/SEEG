#!/bin/bash
module load gcc/6.2.0 python/3.7.4 bcftools/1.13 java/jdk-11.0.11 bedtools/2.27.1
source ~/yw222PythonFolder/spliceai/bin/activate

ROOT=...
DB_DIR=../../databases
CLINVAR_BED=$DB_DIR/clinvar_no_snv_hg19.final.bed
INDIR=../panel_seq_output/merged_vcf
OUTDIR=$INDIR/filtered
SCRIPT_DIR=/n/data1/bch/genetics/lee/elain/TLE/scripts/variant_prioritization
mkdir -p $OUTDIR
mkdir -p $INDIR/intermediate

ANNOTATE_SNV() {
	sample=MH
	variant=snv
	prefix=MH
	input_file=$INDIR/$prefix.normalize.snpeff.clinvar.hgmd.epilepsygeneset.vcf
	# don't remove recurrent variant for now
	# split into missense, splicing, synonymous, and others
	python3 split_vcf.py $INDIR/intermediate/${prefix}_filtered $input_file
	# annotate missense variants by revel and eve
	java -jar ~/snpEff/SnpSift.jar annotate $DB_DIR/revel_hg19.vcf.gz -v $INDIR/intermediate/${prefix}_filtered_missense.vcf > $OUTDIR/${prefix}_filtered_missense_revel.vcf
	java -jar ~/snpEff/SnpSift.jar annotate $DB_DIR/EVE_SNP_hg19_all.vcf.gz -v $OUTDIR/${prefix}_filtered_missense_revel.vcf > $OUTDIR/${prefix}_filtered_missense_revel_eve.vcf
	java -jar ~/snpEff/SnpSift.jar annotate $DB_DIR/CosmicMutantExportCensus_hg19.sorted.cleaned.vcf.gz -v $OUTDIR/${prefix}_filtered_missense_revel_eve.vcf > $OUTDIR/${prefix}_filtered_missense_revel_eve_cosmic.vcf
	# filter missense variants by revel score and eve classes or existence in cosmic annotations
	python3 $SCRIPT_DIR/filter_variant_revel_eve_cosmic.py $OUTDIR/${prefix}_filtered_missense_revel_eve_cosmic.vcf $OUTDIR/${prefix}_filtered_missense_ 0.6 80
	# annotate splicing variants by spliceAI and filter splicing variants by spliceAI scores
	unset PYTHONPATH
	sbatch -N 1 -c 1 -J ${prefix}_spliceai -o $OUTDIR/${prefix}_filtered_spliceai.log --mem=5G -t 0-03:00 -p short --mail-user=... --mail-type=END,FAIL --wrap="spliceai -I $INDIR/intermediate/${prefix}_filtered_splice.vcf -O $OUTDIR/${prefix}_filtered_splice_spliceai.vcf -R hg19/ucsc.hg19.fasta -A grch37; python3 filter_spliceai.py $OUTDIR/${prefix}_filtered_splice_spliceai.vcf 0.8"
}

ANNOTATE_OTHERS() {
	sample=Pisces
	prefix=$sample
	input_file=$INDIR/${prefix}_single.vcf
	grep 
	## pick out CLINVAR (CLINSIG=Pathogenic, Likely_pathogenic, Pathogenic/Likely_pathogenic) pathogenic indels and also those within 10bp of pathogenic CLINVAR variants
	python3 conv_pisces_vcf_to_bed.py $input_file $INDIR/$prefix.bed # somehow some entries have q20, filter those out too
	grep "^#" $input_file > $OUTDIR/$prefix.CLINVAR.vcf
	intersectBed -wa -a $INDIR/$prefix.bed -b $CLINVAR_BED | cut --complement -f3 | uniq >> $OUTDIR/$prefix.CLINVAR.vcf
	rm $INDIR/$prefix.bed
}

ANNOTATE_SNV
ANNOTATE_OTHERS
