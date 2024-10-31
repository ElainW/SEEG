#!/bin/python3
import os
import sys
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from statannot import add_stat_annotation

hot_electrode = pd.read_csv(sys.argv[1], sep="\t", names=['sample', 'avg_cov'])
hot_electrode['category'] = 'amplified'
print(hot_electrode.head())
hot_electrode.loc[hot_electrode["sample"] == "Neu_0476_EZ_T", "category"] = 'unamplified'
cold_electrode = pd.read_csv(sys.argv[2], sep="\t", names=['sample', 'avg_cov'])
cold_electrode['category'] = 'amplified'
cold_electrode.loc[cold_electrode["sample"] == "Neu_0476_EZ_K", "category"] = 'unamplified'
bulk_brain = pd.read_csv(sys.argv[3], sep="\t", names=['sample', 'avg_cov'])
bulk_brain['category'] = 'unamplified'
blood = pd.read_csv(sys.argv[4], sep="\t", names=['sample', 'avg_cov'])
blood['category'] = 'unamplified'
df = pd.concat([hot_electrode, cold_electrode, bulk_brain, blood], ignore_index=True)
print(df.head())
print(df["avg_cov"].mean())

fig, axes = plt.subplots(1, 1, figsize=(7, 5))
sns.boxplot(x="category", y="avg_cov", data=df, ax=axes)
sns.swarmplot(x="category", y="avg_cov", data=df, color="black", size=3, ax=axes)
axes.set_ylabel("Avg coverage", fontsize=16)
axes.set_xlabel("Category", fontsize=16)
axes.set_title("Average coverage of panel sequencing", fontsize=16)
add_stat_annotation(axes, data=df, x="category", y="avg_cov",
                    box_pairs=[("amplified", "unamplified")],
                    test='Mann-Whitney', text_format='full', loc='inside', verbose=2)
plt.savefig("avg_cov_single_Fig2.pdf")