#!/bin/bash

#SBATCH -A m2_esm
#SBATCH -p parallel
#SBATCH -t150
#SBATCH -N1
#SBATCH -n40
#SBATCH --mail-type=ALL
#SBATCH --mail-user=egroot
#SBATCH --mem-per-cpu=3100M

## srun -n1 make_cross_section.py
## srun -n1 read_nc_CM1.py

## scripts are always provided with the python script name to be run and 1. the number of grid cells per kilometre in horizontal and 2. the factor with which lve was mulptiplied (even if 1.0)

srun -n1 python MSE_cross_whout.py  controlling_thetaadv_1.05 5.0 1.0 
srun -n1 python MSE_cross.py controlling_thetaadv_1.05  5.0 1.0
srun -n1 python read_nc_CM1.py controlling_thetaadv_1.05 5.0 1.0
srun -n1 python make_cross_section.py controlling_thetaadv_1.05 5.0 1.0
srun -n1 python wvalues.py controlling_thetaadv_1.05
srun -n1 python dbzvalues.py controlling_thetaadv_1.05

srun -n1 python MSE_cross_whout.py  controlling_thetaadv_1.10 5.0 1.0 
srun -n1 python MSE_cross.py controlling_thetaadv_1.10  5.0 1.0
srun -n1 python read_nc_CM1.py controlling_thetaadv_1.10 5.0 1.0
srun -n1 python make_cross_section.py controlling_thetaadv_1.10 5.0 1.0
srun -n1 python wvalues.py controlling_thetaadv_1.10
srun -n1 python dbzvalues.py controlling_thetaadv_1.10
