#!/bin/bash

#SBATCH -A m2_esm
#SBATCH -p bigmem
#SBATCH -t330
#SBATCH -N1
#SBATCH -n40
#SBATCH --mail-type=ALL
#SBATCH --mail-user=egroot
#SBATCH --mem-per-cpu=12000M

## srun -n1 make_cross_section.py
## srun -n1 read_nc_CM1.py

## scripts are always provided with the python script name to be run and the factor with which lve was mulptiplied (even if 1.0)
srun -n1 python MSE_cross_whout.py coldpool_cubic_res_100m 1.0 
srun -n1 python MSE_cross.py coldpool_cubic_res_100m 1.0
srun -n1 make_cross_section.py coldpool_cubic_res_100m 1.0
srun -n1 read_nc_CM1.py coldpool_cubic_res_100m 1.0



