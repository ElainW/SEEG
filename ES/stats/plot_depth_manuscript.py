#!/bin/python3
import os
import sys
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from statannot import add_stat_annotation

filtered_coverage=pd.read_csv(sys.argv[1], sep='\t', names=['sample', 'avg_cov']) # use filtered_coverage.txt (before Ti subsampling); use filtered_coverage_Ti_subsampled.txt
filtered_coverage['category'] = 'amplified'
filtered_coverage.loc[filtered_coverage["sample"] == "0859_Ti-A", "category"] = 'unamplified'
filtered_coverage.loc[filtered_coverage["sample"] == "0863_Ti-G", "category"] = 'unamplified'

print(filtered_coverage["avg_cov"].mean())

fig, axes = plt.subplots(1, 1, figsize=(7, 5))
sns.boxplot(x="category", y="avg_cov", data=filtered_coverage, ax=axes)
sns.swarmplot(x="category", y="avg_cov", data=filtered_coverage, color="black", size=3, ax=axes)
axes.set_ylabel("Avg coverage", fontsize=16)
axes.set_xlabel("Category", fontsize=16)
axes.set_title("Average coverage of ES", fontsize=16)
add_stat_annotation(axes, data=filtered_coverage, x="category", y="avg_cov",
                    box_pairs=[("amplified", "unamplified")],
                    test='Mann-Whitney', text_format='full', loc='inside', verbose=2)
# plt.savefig("avg_cov_WES_Fig2.png") # before Ti subsampling
plt.savefig("avg_cov_WES_Fig2_Ti_subsampled.pdf")
