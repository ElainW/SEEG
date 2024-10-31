#!/bin/python3
import os
import sys
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from statannot import add_stat_annotation
# python3 plot_filtered_count_manuscript.py filtered_MH_count_complete.tsv filtered_Pisces_count_complete.tsv

mh_df = pd.read_csv(sys.argv[1], sep="\t", names=['sample', 'count', 'category'])
mh_df = mh_df.replace("hot electrode", "amplified")
mh_df = mh_df.replace("cold electrode", "amplified")
mh_df = mh_df.replace("bulk brain", "unamplified")
mh_df = mh_df.replace("blood", "unamplified")
# replace 2 unamplified electrode samples
mh_df.loc[mh_df["sample"] == "Neu_0476_EZ_T", "category"] = 'unamplified'
mh_df.loc[mh_df["sample"] == "Neu_0476_EZ_K", "category"] = 'unamplified'
# print(mh_df)

pisces_df = pd.read_csv(sys.argv[2], sep="\t", names=['sample', 'count', 'category'])
pisces_df = pisces_df.replace("hot electrode", "amplified")
pisces_df = pisces_df.replace("cold electrode", "amplified")
pisces_df = pisces_df.replace("bulk brain", "unamplified")
pisces_df = pisces_df.replace("blood", "unamplified")
# replace 2 unamplified electrode samples
pisces_df.loc[pisces_df["sample"] == "Neu_0476_EZ_T", "category"] = 'unamplified'
pisces_df.loc[pisces_df["sample"] == "Neu_0476_EZ_K", "category"] = 'unamplified'
# print(pisces_df)
fig, axes = plt.subplots(1, 2, figsize=(14, 5))
sns.boxplot(x="category", y="count", data=mh_df, ax=axes[0])
sns.swarmplot(x="category", y="count", data=mh_df, color="black", size=3, ax=axes[0])
axes[0].set_ylabel("Count", fontsize=16)
axes[0].set_xlabel("Category", fontsize=16)
axes[0].set_title("Somatic SNV count in panel sequencing", fontsize=16)
add_stat_annotation(axes[0], data=mh_df, x="category", y="count",
                    box_pairs=[("amplified", "unamplified")],
                    test='Mann-Whitney', text_format='full', loc='inside', verbose=2)
sns.boxplot(x="category", y="count", data=pisces_df, ax=axes[1])
sns.swarmplot(x="category", y="count", data=pisces_df, color="black", size=3, ax=axes[1])
axes[1].set_ylabel("Count", fontsize=16)
axes[1].set_xlabel("Category", fontsize=16)
axes[1].set_title("Somatic indel count in panel sequencing", fontsize=16)
add_stat_annotation(axes[1], data=pisces_df, x="category", y="count",
                    box_pairs=[("amplified", "unamplified")],
                    test='Mann-Whitney', text_format='full', loc='inside', verbose=2)
plt.savefig("count_single_filtered_MH_pisces_manuscript.pdf")