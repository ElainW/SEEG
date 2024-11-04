#!/bin/python3
# import matplotlib.pyplot as plt
import pandas as pd
import argparse
from os.path import basename

def parse_arguments():
	parser = argparse.ArgumentParser("calculate avg coverage for samples")
	parser.add_argument("-i", dest="input", type=str, required=True, help="count table")
	parser.add_argument("-o", dest="output", type=str, required=True, help="avg cov stats output file")
	args = parser.parse_args()
	return args

if __name__ == '__main__':
	args = parse_arguments()
	input = args.input

	df = pd.read_csv(args.input, sep=" ", names=["cov", "count"])
	total_bp = df["count"].sum()
	total_seq_cov = df["cov"].dot(df["count"])
	avg_cov = total_seq_cov/total_bp
	with open(args.output, 'w') as fout:
		fout.write(str(avg_cov))
