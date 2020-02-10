#!/bin/bash

#SBATCH -A m2_esm
#SBATCH -p parallel
#SBATCH -t150
#SBATCH -N1
#SBATCH -n40
#SBATCH --mail-type=ALL
#SBATCH --mail-user=egroot
#SBATCH --mem-per-cpu=3100M
###srun -n1 modules_for_python.sh
srun -n1 python integrated_vertical_profiles.py controlling_MSEadv_0.96 1.0 ref_res_1km 1.0 ref_res_1km 1.0 ref_res_1km 1.0
