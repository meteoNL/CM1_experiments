#!/bin/bash

#SBATCH -A m2_esm
#SBATCH -p parallel
#SBATCH -t300
#SBATCH -N1
#SBATCH -n40
#SBATCH --mail-type=ALL
#SBATCH --mail-user=egroot
#SBATCH --mem-per-cpu=3100M
###srun -n1 modules_for_python.sh
srun -n1 python integrated_vertical_profiles.py bubble_control_ref_200m 1.0 bubble_controlling_lve_1.1 1.1 bubble_controlling_lve_1.2 1.2 bubble_controlling_vadv_0.00 1.0
srun -n1 python integrated_vertical_profiles.py bubble_control_ref_200m 1.0 bubble_controlling_vadv_0.50 1.0 bubble_controlling_vadv_0.80 1.0 bubble_controlling_vadv_1.50 1.0
srun -n1 python integrated_vertical_profiles.py bubble_control_ref_200m 1.0 bubble_controlling_qvadv_0.80 1.0 bubble_controlling_qvadv_1.20 1.0 bubble_ref_res_1km 1.0
srun -n1 python integrated_vertical_profiles.py bubble_control_ref_200m 1.0 bubble_cubic_res_200m 1.0 bubble_ref_res_500m 1.0 bubble_ref_res_1km 1.0
srun -n1 python integrated_vertical_profiles.py bubble_control_ref_200m 1.0 bubble_ENS_01 1.0 bubble_ENS_02 1.0 bubble_ENS_03 1.0
srun -n1 python integrated_vertical_profiles.py bubble_control_ref_200m 1.0 bubble_ENS_04 1.0 bubble_ENS_05 1.0 bubble_ENS_06 1.0
srun -n1 python integrated_vertical_profiles.py bubble_control_ref_200m 1.0 bubble_ENS_07 1.0 bubble_ENS_08 1.0 bubble_ENS_09 1.0
