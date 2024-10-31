#!/bin/python3

import sys
sample = sys.argv[3]
with open(sys.argv[1], 'r') as f_in, open(sys.argv[2], 'w') as f_out:
	# write header
	f_out.write('##fileformat=VCF_fake\n##reference=hg19\n##INFO=<ID=DP,Number=1,Type=Integer,Description="Total Depth">\n##INFO=<ID=AD,Number=R,Type=Integer,Description="Allelic depths for the REF, ALT1, and ALT2 alleles in the order listed">\n##INFO=<ID=AF,Number=A,Type=Float,Description="Minor Allele 1 Frequency">\n##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype, artificially set to 0/1 as MosaicHunter doesn\'t provide a GT">\n##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Total Depth (major allele depth + minor allele depth + minor allele 2 depth)">\n##FORMAT=<ID=AD,Number=1,Type=Integer,Description="Major Allele Depth (REF), Minor Allele 1 Depth (ALT), Minor Allele 2 Depth">\n##FORMAT=<ID=AF,Number=A,Type=Float,Description="Minor Allele 1 Frequency">\n##FORMAT=<ID=SAMPLE,Number=1,Type=String,Description="Sample ID">\n')
	f_out.write(f"#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t{sample}\n")
	for lines in f_in:
		fields = lines.split('\t')
		chrm = fields[0]
		pos = fields[1]
		ref = fields[2]
		alt = fields[3]
		major_depth = fields[5]
		minor_depth = fields[6]
		minor2_depth = fields[7]
		depth = int(major_depth)+int(minor_depth)+int(minor2_depth)
		af = round(int(minor_depth)/depth, 4)
		f_out.write("\t".join([chrm, pos, ".", ref, alt, ".", "PASS", f"DP={depth};AD={major_depth},{minor_depth},{minor2_depth};AF={af}", "GT:DP:AD:AF", f"0/1:{depth}:{major_depth},{minor_depth}:{af}"]) + "\n")
