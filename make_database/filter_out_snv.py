#!/bin/python3
import sys

with open(sys.argv[1], 'r') as f_in, open(sys.argv[2], 'w') as f_out:
	for lines in f_in:
		if lines[0] == "#":
			f_out.write(lines)
			continue
		fields = lines.split('\t')
		ref, alt = fields[3], fields[4]
		if len(ref) == 1 and len(alt) == 1:
			continue
		f_out.write(lines)