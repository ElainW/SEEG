#!/bin/python3

import sys
sample_list = ["0863_Ti-G", "0859_Ti-A", "0859_A_", "0863_K", "0864_F", "0861_N_", "0868_R", "0871_J", "0500_B_", "0873_H"]
for sample in sample_list:
	with open(sys.argv[2] + sample + ".vcf", 'w') as f_out:
		# write header
		f_out.write('##fileformat=VCF_fake\n##reference=hg19\n##INFO=<ID=DP,Number=1,Type=Integer,Description="Total Depth">\n##INFO=<ID=AD,Number=R,Type=Integer,Description="Allelic depths for the REF, ALT alleles in the order listed">\n##INFO=<ID=AF,Number=A,Type=Float,Description="Minor Allele Frequency">\n##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Total Depth (major allele depth + minor allele depth)">\n##FORMAT=<ID=AD,Number=1,Type=Integer,Description="Major Allele Depth (REF), Minor Allele Depth (ALT)">\n##FORMAT=<ID=AF,Number=A,Type=Float,Description="Minor Allele Frequency">\n')
		f_out.write(f"#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t{sample}\n")
with open(sys.argv[1], 'r') as f_in:
	for lines in f_in:
		fields = lines.split('\t')
		chrm = fields[0]
		pos = fields[1]
		ref = fields[2]
		alt = fields[3]
		major_depth = fields[4]
		minor_depth = fields[5]
		sample = fields[6].rstrip()
		depth = int(major_depth)+int(minor_depth)
		af = round(int(minor_depth)/depth, 4)
		with open(sys.argv[2] + sample + ".vcf", 'a') as f_out:
			f_out.write("\t".join([chrm, pos, ".", ref, alt, ".", "PASS", f"DP={depth};AD={major_depth},{minor_depth};AF={af}", "DP:AD:AF", f"{depth}:{major_depth},{minor_depth}:{af}", sample]) + "\n")
