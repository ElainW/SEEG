#!/bin/bash
#SBATCH -J lift_cosmic_vcf
#SBATCH -N 1
#SBATCH -c 1
#SBATCH -o lift_cosmic_vcf.log
#SBATCH --mem 5G
#SBATCH -t 0-00:03
#SBATCH -p short
#SBATCH --mail-user=yilanwang@g.harvard.edu
#SBATCH --mail-type=FAIL,END

module load gcc/6.2.0 java/jdk-1.8u112
OUTDIR=/n/groups/walsh/indData/elain/databases
java -Xmx5g -jar ~/picard/build/libs/picard.jar LiftoverVcf \
	I=/n/groups/walsh/indData/Sattar/WES/KMTS/variant_prioritization/databases/cosmic_vcf/CosmicMutantExportCensus.sorted.cleaned.vcf.gz \
	O=$OUTDIR/CosmicMutantExportCensus_hg19.sorted.cleaned.vcf.gz \
	CHAIN=$OUTDIR/hg38ToHg19.over.chain.gz \
	REJECT=$OUTDIR/CosmicMutantExportCensus_hg38tohg19_rejected.vcf \
	R=/n/data1/bch/genetics/lee/reference/hg19/ucsc.hg19.fasta \
	TMP_DIR=/n/scratch3/users/y/yw222/

# had to manually change the header of INFO field Number from -1 to .
# 14 (0.0267% failed the conversion)