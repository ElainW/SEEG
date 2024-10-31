#!/bin/bash
#SBATCH -J gen_cosmic_cancer_census_vcf
#SBATCH -N 1
#SBATCH -c 1
#SBATCH -o gen_cosmic_cancer_census_vcf.log
#SBATCH --mem 1G
#SBATCH -t 0-00:05
#SBATCH -p priority
#SBATCH --mail-user=yilanwang@g.harvard.edu
#SBATCH --mail-type=FAIL,END
module load gcc/6.2.0 bcftools/1.13 python/3.7.4
DIR=/n/groups/walsh/indData/Sattar/WES/KMTS/variant_prioritization/databases/cosmic_vcf

# this is the previous version, has all the variants, unclear which one is pathogenic given the INFO
# gunzip CosmicCodingMuts.vcf.gz
# add chr to CHRM
#grep "^#" $DIR/CosmicCodingMuts.vcf > $DIR/header.tmp
#grep -v "^#" $DIR/CosmicCodingMuts.vcf | grep -v "^MT" | sed 's/^/chr/' > $DIR/content.tmp
#cat $DIR/header.tmp $DIR/content.tmp | bgzip -c > $DIR/CosmicCodingMuts_hg38_v95_cleaned.vcf.gz
#tabix $DIR/CosmicCodingMuts_hg38_v95_cleaned.vcf.gz
#rm $DIR/*.tmp

# second attempt using mutations in cancer census genes
gunzip $DIR/CosmicMutantExportCensus.tsv.gz # only select columns: Gene name,Primary site,Primary histology,Genome-wide screen,GENOMIC_MUTATION_ID,Mutation zygosity,Mutation strand,Mutation somatic status,HGVSG
grep "^#" $DIR/CosmicCodingMuts.vcf > $DIR/Cosmic_header.txt
grep "^##contig" /n/groups/walsh/indData/Sattar/WES/KMTS/variant_prioritization/isec3.vcf >> $DIR/Cosmic_header.txt
cat $DIR/Cosmic_header.txt > $DIR/CosmicMutantExportCensus.vcf
python3 clean_CosmicCensus.py $DIR/CosmicMutantExportCensus.tsv $DIR/CosmicMutantExportCensus.vcf $DIR/CosmicMutantExportCensus.other.tsv
echo "finished extracting SNVs"
echo

## filter out snvs from the coding variants vcf to speed up the grep step
python3 filter_out_snv.py $DIR/CosmicCodingMuts.vcf $DIR/CosmicCodingMuts_no_snvs.vcf

# to speed up the process, split $DIR/CosmicCodingMuts_no_snvs.vcf into equal chunks to run in parallel
split -l 16869 -d --additional-suffix=.tmp $DIR/CosmicMutantExportCensus.other.tsv $DIR/Cosmic_other
rm -f $DIR/Cosmic_other_*.vcf.tmp
i=0
for f in $DIR/Cosmic_other*.tmp; do
	printf "" > $DIR/Cosmic_other_${i}.vcf.tmp
	sbatch -J ${i}_grep_cosmic -N 1 -c 1 -o grep_cosmic_$i.log --mem=1G -t 0-5:00 -p short --mail-user=yilanwang@g.harvard.edu --mail-type=FAIL,END cosmic_grep.sh $f $DIR $i
	i=$((i+1))								
done

# merge grep results to the final output and gzip and index
cat $DIR/Cosmic_other_*.vcf.tmp >> $DIR/CosmicMutantExportCensus.vcf
rm $DIR/*.tmp
bcftools sort -m 800M -o $DIR/CosmicMutantExportCensus.sorted.vcf -Ov $DIR/CosmicMutantExportCensus.vcf # Error encountered while parsing the input at chr4:54727457 (many COSMIC variants at this locus)
bgzip -c $DIR/CosmicMutantExportCensus.sorted.vcf > $DIR/CosmicMutantExportCensus.sorted.vcf.gz
tabix $DIR/CosmicMutantExportCensus.sorted.vcf.gz
