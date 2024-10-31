#!/bin/python3
import os
import sys

with open(sys.argv[1], 'r') as f_in, open(sys.argv[2], 'w') as f_out:
	for lines in f_in:
		if lines[0] == '#':
			if lines[1] == '#':
				continue
			else:
				fields = lines.split('\t')
				fields.insert(2, fields[1]+'+1')
				f_out.write("\t".join(fields))
		else:
			fields = lines.split('\t')
			# filter out entries with FILTER!=PASS
			if fields[6] == "PASS":
				fields.insert(2, str(int(fields[1])+1))
				f_out.write("\t".join(fields))