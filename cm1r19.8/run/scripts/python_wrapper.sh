#!/bin/bash

#SBATCH -A m2_esm
#SBATCH -p parallel
#SBATCH -t330
#SBATCH -N1
#SBATCH -n40
#SBATCH --mail-type=ALL
#SBATCH --mail-user=egroot
#SBATCH --mem-per-cpu=3100M

## srun -n1 make_cross_section.py

## scripts are always provided with the python script name to be run and the factor with which lve was mulptiplied (even if 1.0)
srun -n1 python MSE_cross_whout.py controlling_vadv_0.0 1.0 
srun -n1 python MSE_cross.py controlling_vadv_0.0 1.0

srun -n1 python MSE_cross_whout.py controlling_vadv_0.5 1.0 
srun -n1 python MSE_cross.py controlling_vadv_0.5 1.0

srun -n1 python MSE_cross_whout.py controlling_vadv_0.8 1.0 
srun -n1 python MSE_cross.py controlling_vadv_0.8 1.0

srun -n1 python MSE_cross_whout.py controlling_vadv_1.5 1.0 
srun -n1 python MSE_cross.py controlling_vadv_1.5 1.0

srun -n1 python MSE_cross_whout.py control_ref_200m 1.0 
srun -n1 python MSE_cross.py control_ref_200m 1.0

srun -n1 python MSE_cross_whout.py cubic_res_200m 1.0 
srun -n1 python MSE_cross.py cubic_res_200m 1.0

srun -n1 python MSE_cross_whout.py ENS_01 1.0 
srun -n1 python MSE_cross.py ENS_01 1.0

srun -n1 python MSE_cross_whout.py ENS_02 1.0 
srun -n1 python MSE_cross.py ENS_02 1.0

srun -n1 python MSE_cross_whout.py ENS_03 1.0 
srun -n1 python MSE_cross.py ENS_03 1.0

srun -n1 python MSE_cross_whout.py ENS_04 1.0 
srun -n1 python MSE_cross.py ENS_04 1.0


srun -n1 python MSE_cross_whout.py ENS_05 1.0 
srun -n1 python MSE_cross.py ENS_05 1.0

srun -n1 python MSE_cross_whout.py ENS_06 1.0 
srun -n1 python MSE_cross.py ENS_06 1.0

srun -n1 python MSE_cross_whout.py ENS_07 1.0 
srun -n1 python MSE_cross.py ENS_07 1.0

srun -n1 python MSE_cross_whout.py ENS_08 1.0 
srun -n1 python MSE_cross.py ENS_08 1.0

srun -n1 python MSE_cross_whout.py ENS_09 1.0 
srun -n1 python MSE_cross.py ENS_09 1.0

srun -n1 python MSE_cross_whout.py ref_res_1km 1.0 
srun -n1 python MSE_cross.py ref_res_1km 1.0

srun -n1 python MSE_cross_whout.py ref_res_500m 1.0 
srun -n1 python MSE_cross.py ref_res_500m 1.0




