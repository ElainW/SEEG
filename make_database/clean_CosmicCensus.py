#!/bin/python3
# this script convert the SNVs from the input .tsv file into .vcf and also parses out the COSMIC ID and INFO field for other types of variants (the REF, ALT info can be found in the follow-up script)
import os
import sys
import re

with open(sys.argv[1], 'r', encoding='unicode_escape') as f_in, open(sys.argv[2], 'a') as f_out, open(sys.argv[3], 'w') as f_out_tmp:
	for lines in f_in:
		fields = lines.rstrip('\n').split('\t')
		if fields[0] == "Gene name":
			continue
		screen, cosmic_id, zygosity, strand, somatic_status, HGVSG = 'NA', 'NA', 'NA', 'NA', 'NA', 'NA'
		gene_name, primary_site, primary_histology, screen, cosmic_id, zygosity, strand, somatic_status, HGVSG = fields[0], fields[7], fields[11], fields[15], fields[16], fields[22], fields[26], fields[30], fields[39]
		INFO = f"GENE={gene_name};STRAND={strand};SITE={primary_site};HISTOLOGY={primary_histology};SCREEN={screen};ZYGOSITY={zygosity};SOMATIC_STATUS={somatic_status.replace(' ', '_')}"
		if re.match("^\d+:g\.[0-9]+[ATCG]>[ATCG]$", HGVSG):
			chrm, _, pos_ref, ALT = re.split('[:.>]', HGVSG)
			CHROM = "chr" + chrm
			POS, REF = pos_ref[:-1], pos_ref[-1]
			f_out.write("\t".join([CHROM, POS, cosmic_id, REF, ALT, ".", ".", INFO]) + "\n")
		else:
			if cosmic_id != "":
				f_out_tmp.write("\t".join([cosmic_id, INFO]) + "\n")
