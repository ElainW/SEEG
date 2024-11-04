#!/bin/python3
# 2022/03/22 made the change such that revel_eve_cosmic contains any variants that pass the revel score filtering OR EVE class pathogenic OR annotated in COSMIC
import os
import sys

revel_cutoff = float(sys.argv[3])
eve_class = sys.argv[4]
eve_class_prefix = "Class" + eve_class + "="
cosmic_prefix = "SOMATIC_STATUS="
with open(sys.argv[1], 'r') as f_in, open(sys.argv[2]+f"revel{revel_cutoff}.vcf", 'w') as f_r, open(sys.argv[2]+f"eveclass{eve_class}.vcf", 'w') as f_e, open(sys.argv[2]+f"revel{revel_cutoff}_eveclass{eve_class}_cosmic.vcf", 'w') as f_b:
	for lines in f_in:
		in_both = False
		if lines[0] == "#":
			f_r.write(lines)
			f_e.write(lines)
			f_b.write(lines)
			continue
		fields = lines.rstrip().split('\t')
		info = fields[7]
		info_list = info.split(';')
		for score in info_list:
			if score[:5]=="RESC=":
				revel = score.lstrip('RESC=')
				if ',' in revel:
					revel_score = float(revel.split(',')[0])
				else:
					revel_score = float(revel)
				if revel_score >= revel_cutoff:
					f_r.write(lines)
					f_b.write(lines)
					in_both = True
			
			if score[:15] == cosmic_prefix and not in_both:
				f_b.write(lines)
				in_both = True
			
			if score[:8]==eve_class_prefix:
				eve_class = score.lstrip(eve_class_prefix)
				if eve_class == "Pathogenic":
					f_e.write(lines)
					if not in_both:
						f_b.write(lines)
				
