#!/bin/bash

#SBATCH -A m2_esm
#SBATCH -p bigmem
#SBATCH -t45
#SBATCH -N1
#SBATCH -n40
#SBATCH --mail-type=ALL
#SBATCH --mail-user=egroot
#SBATCH --mem-per-cpu=12000M
###srun -n1 modules_for_python.sh
srun -n1 python integrated_vertical_profiles.py 
