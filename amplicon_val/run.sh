#!/bin/bash

module load gcc/6.2.0 samtools/0.1.19 bwa/0.7.15 bedtools/2.27.1 java/jdk-1.8u112 R/4.0.1
#while read LINE; do
#	sbatch -J $LINE -o ${LINE}.log --mem=8G -t 0-00:30 -N 1 -c 4 -p short --mail-user=yilanwang@g.harvard.edu --mail-type=FAIL,END --wrap="bash map.sh $LINE 4 bam 30-699833257"
#done < barcode_id.txt

#while read LINE; do
#	sbatch -J $LINE -o ${LINE}.log --mem=8G -t 0-00:30 -N 1 -c 4 -p short --mail-user=yilanwang@g.harvard.edu --mail-type=FAIL,END --wrap="bash map.sh $LINE 4 bam2 30-716905337"
#done < barcode_id2.txt
#
#while read LINE; do
#	sbatch -J $LINE -o ${LINE}.log --mem=8G -t 0-00:30 -N 1 -c 4 -p short --mail-user=yilanwang@g.harvard.edu --mail-type=FAIL,END --wrap="bash map.sh $LINE 4 bam3 30-717571369"
#done < barcode_id3.txt

#while read LINE; do
#	sbatch -J $LINE -o ${LINE}.log --mem=8G -t 0-00:30 -N 1 -c 4 -p short --mail-user=yilanwang@g.harvard.edu --mail-type=FAIL,END --wrap="bash map.sh $LINE 4 bam4 30-754208006"
#done < barcode_id4.txt

#while read LINE; do
#	sbatch -J $LINE -o ${LINE}.log --mem=8G -t 0-00:30 -N 1 -c 4 -p short --mail-user=yilanwang@g.harvard.edu --mail-type=FAIL,END --wrap="bash map.sh $LINE 4 bam5 30-767016606"
#done < barcode_id5.txt

# while read LINE; do
# 	sbatch -J $LINE -o ${LINE}.log --mem=8G -t 0-00:30 -N 1 -c 4 -p short --mail-user=yilanwang@g.harvard.edu --mail-type=FAIL,END --wrap="bash map.sh $LINE 4 bam6 30-821805347"
# done < barcode_id6.txt

# while read LINE; do
# 	sbatch -J $LINE -o ${LINE}.log --mem=8G -t 0-00:30 -N 1 -c 4 -p short --mail-user=yilanwang@g.harvard.edu --mail-type=FAIL,END --wrap="bash map.sh $LINE 4 bam7 30-870026838"
# done < barcode_id7.txt

while read LINE; do
	sbatch -J $LINE -o ${LINE}.log --mem=8G -t 0-00:30 -N 1 -c 4 -p short --mail-user=yilanwang@g.harvard.edu --mail-type=FAIL,END --wrap="bash map.sh $LINE 4 bam8 30-876552567"
done < barcode_id8.txt