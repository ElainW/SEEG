#!/bin/python3
import os
import sys
# from cmd_runner import *

# this scripts first write out the variants (mostly indels) that have CLINSIG=pathogenic/likely pathogenic labels in the annotations
with open(sys.argv[1], 'r') as f_in, open(sys.argv[2], 'w') as f_out, open(sys.argv[2] + ".tmp", 'w') as f_tmp:
	for lines in f_in:
		if lines[0] == "#":
			continue
		fields = lines.rstrip().split('\t')
		for info in fields[7].split(";"):
			if info[:7] == "CLNSIG=":
				clnsig = info[7:]
				if ('pathogenic' in clnsig or 'Pathogenic' in clnsig) and 'Conflicting' not in clnsig:
					f_out.write(lines)
				else:
					chrm = fields[0]
					start = str(int(fields[1]) - 1)
					end = fields[1]
					outlist = [chrm, start, end]
					outlist.extend(fields[2:])
					f_tmp.write('\t'.join(outlist) + '\n')