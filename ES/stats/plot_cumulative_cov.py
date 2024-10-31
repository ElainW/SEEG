import sys
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
import numpy as np
import pandas as pd


count_df_dir = "/n/groups/walsh/indData/elain/DeepWES4_7/final/"
barcode_list = ["0863_Ti-G", "0859_Ti-A", "0859_A_", "0863_K", "0864_F", "0861_N_", "0868_R", "0871_J", "0500_B_", "0873_H"]
# to map the electrode list to patient ID
barcode_sample_dict = {"0863_Ti-G":'Patient 4 (UA)', "0859_Ti-A":'Patient 1 (UA)', "0859_A_":'Patient 1 (A)', 
"0863_K":'Patient 4 (A)', "0864_F":'Patient 5 (A)', '0861_N_':'Patient 3 (A)',
"0868_R":'Patient 6 (A)', "0871_J":'Patient 8 (A)', '0500_B_':'Patient 2 (A)',
'0873_H':'Patient 10 (A)'}
output = "WES_cum_depth.pdf"

fig, axes = plt.subplots(1, 1, figsize=(7, 5))

cov_list = list(np.arange(1,5001))
df = pd.Series(cov_list).to_frame(name="cov")
del cov_list


for barcode in barcode_list:
	count_tsv = count_df_dir + barcode + ".counts"
	barcode_df = pd.read_csv(count_tsv, sep=" ", names=["cov", "count"])
	total_bp = barcode_df["count"].sum()
	barcode_df["count"] = barcode_df["count"]/total_bp
	barcode_df = pd.DataFrame(dict(cov=barcode_df["cov"], sum=barcode_df["count"].cumsum()))
	df[barcode_sample_dict[barcode]] = barcode_df["sum"]

# to be colorblind friendly
linestyles = ['dashed', 'solid', 'solid', 'dashdot', 'solid', 'dotted', 'dashed', 'dotted', 'dashed', 'dashdot']
colors = ['blue', 'blue', 'orange', 'orange', 'green', 'orange', 'green', 'green', 'orange', 'green']

y_axis = [barcode_sample_dict[y] for y in barcode_list]
legend_elements = []
for i, patient in enumerate(y_axis):
	print(patient, colors[i], linestyles[i])
	plt.plot(df["cov"], df[patient], color=colors[i], linestyle=linestyles[i])
	legend_elements.append(Line2D([0], [0], color=colors[i], lw=1, linestyle=linestyles[i], label=patient))
order = [1,0,2,8,5,3,4,6,7,9]
plt.legend(handles=[legend_elements[idx] for idx in order], loc='center right')
plt.ylabel("Percentage", fontsize=16)
plt.xlabel("Depth", fontsize=16)
plt.axvline(x=500, color='black', linestyle="--")
plt.title("ES sequencing depth cumulative distribution", fontsize=16)
plt.xlim(1,5000)
# # to sort the legends
# handles, labels = plt.gca().get_legend_handles_labels()
# order = [1,0,2,8,5,3,4,6,7,9]
# plt.legend([handles[idx] for idx in order],[labels[idx] for idx in order])

plt.savefig(output)
# to get the percentage of depth with <=500x
print(df.loc[df['cov'] == 500])