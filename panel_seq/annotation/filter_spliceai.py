#!/bin/python3
import os
import sys

cutoff=float(sys.argv[2])
prefix=sys.argv[1].split('.')[0]
with open(sys.argv[1], 'r') as f_in, open(prefix + sys.argv[2] + ".vcf", 'w') as f_out:
	for lines in f_in:
		if lines[0] == "#":
			f_out.write(lines)
			continue
		info = lines.split("\t")[7]
		spliceai = info.split(";")[-1]
		if spliceai[:8] == "SpliceAI":
			fields = spliceai.split("|")
			DS_AG, DS_AL, DS_DG, DS_DL = fields[2:6]
			if DS_AG == "." or DS_AL == "." or DS_DG == "." or DS_DL == ".":
				continue
			if float(DS_AG) >= cutoff or float(DS_AL) >= cutoff or float(DS_DG) >= cutoff or float(DS_DL) >= cutoff:
				f_out.write(lines)
