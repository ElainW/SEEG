#!/user/python3
import os
import sys

with open(sys.argv[1], 'r') as f_in, open(sys.argv[2], 'w') as f_out:
	for lines in f_in:
		fields = lines.rstrip().split('\t')
		if lines[:2] == "##":
			continue
		if lines[0] == "#":
			sample_list = fields[9:]
		else:
			for i, entry in enumerate(fields[9:]):
				if entry.split(":")[-1] != ".":
					f_out.write("\t".join([fields[0], fields[1], fields[3], fields[4],fields[7],sample_list[i],entry.split(":")[-1]]) + "\n")