#!/bin/bash

#SBATCH -A m2_esm
#SBATCH -p parallel
#SBATCH -t50
#SBATCH -N11
#SBATCH -n440
#SBATCH --mail-type=ALL
#SBATCH --mail-user=egroot
#SBATCH --mem-per-cpu=3100M

cd /lustre/miifs01/project/m2_jgu-w2w/w2w/egroot/CM1/cm1r19.8/run/scripts

srun -n440 ./read_nc_CM1.py
####srun -n320 ./integrated_vertical_profiles.py
####srun -n320 ./MSE_cross.py
####srun -n320 ./MSE_cross_whout.py
#####srun -n320 ./make_cross_section.py






