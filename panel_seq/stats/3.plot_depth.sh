#!/bin/bash
module load gcc/6.2.0 python/3.7.4
source ~/yw222PythonFolder/python_bam/bin/activate

# python3 plot_depth.py hot_electrode_bamlist_single_depth.txt cold_electrode_bamlist_single_depth.txt bulk_brain_bamlist_single_depth.txt blood_bamlist_single_depth.txt
python3 plot_depth_manuscript.py hot_electrode_bamlist_single_depth.txt cold_electrode_bamlist_single_depth.txt bulk_brain_bamlist_single_depth.txt blood_bamlist_single_depth.txt