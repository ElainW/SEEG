#!/bin/python3
import sys
import os
from scipy import stats
import pandas as pd

#TLE_count = pd.read_csv(sys.argv[1], sep='\t', names=['sample', 'count'])
TLE_AF = pd.read_csv(sys.argv[1], sep='\t', names=['sample', 'AF'])
#normal_count = pd.read_csv(sys.argv[2], sep='\t', names=['sample', 'count'])
normal_AF = pd.read_csv(sys.argv[2], sep='\t', names=['sample','AF'])
variable1 = sys.argv[3]
variable2 = sys.argv[4]

# first test for normality
# TLE_count_p = stats.shapiro(TLE_count['count'])[1]
# normal_count_p = stats.shapiro(normal_count['count'])[1]
TLE_AF_p = stats.shapiro(TLE_AF['AF'])[1]
normal_AF_p = stats.shapiro(normal_AF['AF'])[1]
# print(f"Testing normality\nTLE count p-value: {TLE_count_p}\nnormal count p-value: {normal_count_p}\n")
print(f"TLE AF p-value: {TLE_AF_p}\nnormal AF p-value: {normal_AF_p}")

# second test for equality of variances
def test_of_homogeneity(p1, p2, v1, v2):
	if p1 >= 0.05 and p2 >= 0.05:
		print("Not enough evidence to reject the null hypothesis that the two distributions are normal. Use the Barlett test")
		stat, p = stats.bartlett(v1, v2)
	else:
		print("Reject the null hypothesis that the two distributions are normal. Use the levene test")
		stat, p = stats.levene(v1, v2)
	# if p < 0.05:
	# 	print("The variances are most likely unequal")
	# else:
	# 	print("We don't have sufficient evidence to claim that the variances are unequal")
	return p

# p_count = test_of_homogeneity(TLE_count_p, normal_count_p, TLE_count['count'], normal_count['count'])
p_AF = test_of_homogeneity(TLE_AF_p, normal_AF_p, TLE_AF['AF'], normal_AF['AF'])

# third test the difference in mean
def test_of_equality(p1, p2, p, v1, v2):
	print(v1.mean(), v2.mean())
	if p1 >= 0.05 and p2 >= 0.05 and p >= 0.05:
		# print("Normality + equal variance. t-test")
		stat, p_val = stats.ttest_ind(v1, v2)
	else:
		# print("Either no normality or unequal variance. Wilcoxon rank-sum test")
		stat, p_val = stats.ranksums(v1, v2)
	if p_val < 0.05/6:
		print(f"The means are most likely unequal because p={p_val}\n\n\n")
	else:
		print(f"We don't have sufficient evidence to claim that the means are unequal because p={p_val}\n\n\n")

# test_of_equality(TLE_count_p, normal_count_p, p_count, TLE_count['count'], normal_count['count'])
test_of_equality(TLE_AF_p, normal_AF_p, p_AF, TLE_AF['AF'], normal_AF['AF'])