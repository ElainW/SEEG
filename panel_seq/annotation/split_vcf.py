#!/bin/python3
import os
import sys

prefix=sys.argv[1]
with open(sys.argv[2], 'r') as f_in, open(prefix + '_missense.vcf', 'w') as f_mis, open(prefix + '_splice.vcf', 'w') as f_splice, open(prefix + '_synonymous.vcf', 'w') as f_syn, open(prefix + '_others.vcf', 'w') as f_other, open(prefix + "_start_stop_variant.vcf", 'w') as f_ss:
	for lines in f_in:
		if lines[0] == '#':
			f_mis.write(lines)
			f_splice.write(lines)
			f_syn.write(lines)
			f_other.write(lines)
			f_ss.write(lines)
			continue
		fields = lines.strip().split('\t')
		sub_fields = fields[7].split('|')
		others = True
		if ',' in sub_fields[1]:
			if sub_fields[2] == 'missense_variant' or 'missense' in sub_fields[2]:
				f_mis.write(lines)
				others = False
			if 'splice' in sub_fields[2]:
				f_splice.write(lines)
				others = False
			if sub_fields[2] == 'synonymous_variant':
				f_syn.write(lines)
				others = False
			if 'start' in sub_fields[2] or 'stop' in sub_fields[2]:
				f_ss.write(lines)
				others = False
			if others:
				f_other.write(lines)
		else:
			if sub_fields[1] == 'missense_variant' or 'missense' in sub_fields[1]:
				f_mis.write(lines)
				others = False
			if 'splice' in sub_fields[1]:
				f_splice.write(lines)
				others = False
			if sub_fields[1] == 'synonymous_variant':
				f_syn.write(lines)
				others = False
			if 'start' in sub_fields[1] or 'stop' in sub_fields[1]:
				f_ss.write(lines)
				others = False
			if others:
				f_other.write(lines)