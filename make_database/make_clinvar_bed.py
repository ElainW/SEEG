#!/bin/python3
import os
import sys

with open(sys.argv[1], 'r') as f_in, open(sys.argv[2], 'w') as f_out:
	f_out.write("#chr\tstart\tend\tCLINSIG\n")
	for lines in f_in:
		if lines[0] == "#":
			continue
		fields = lines.rstrip().split('\t')
		for info in fields[2].split(";"):
			if info[:7] == "CLNSIG=":
				clnsig = info[7:]
				if ('pathogenic' in clnsig or 'Pathogenic' in clnsig) and 'Conflicting' not in clnsig:
					chrm = "chr" + fields[0]
					start = int(fields[1]) - 10
					end = int(fields[1]) + 10
					f_out.write('\t'.join([chrm, str(start), str(end), clnsig]) + '\n')
		