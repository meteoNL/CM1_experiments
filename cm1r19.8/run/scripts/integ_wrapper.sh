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
srun -n1 python integrated_vertical_profiles.py controlling_MSEadv_0.8__incomplete 1.0 controlling_MSEadv_1.2__incomplete 1.0 controlling_MSEadv_0.995 1.0 ENS_09 1.0
srun -n1 python integrated_vertical_profiles.py ENS_01 1.0 ENS_02 1.0 ENS_03 1.0 ENS_04 1.0
srun -n1 python integrated_vertical_profiles.py ENS_05 1.0 ENS_06 1.0 ENS_07 1.0 ENS_08 1.0
srun -n1 python integrated_vertical_profiles.py controlling_vadv_0.0 1.0 controlling_vadv_0.5 1.0 controlling_vadv_0.8 1.0 controlling_vadv_1.5 1.0

