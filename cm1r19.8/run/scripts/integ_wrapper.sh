#!/bin/bash
### SBATCH recipe
#SBATCH -A m2_esm
#SBATCH -p bigmem
#SBATCH -t40
#SBATCH -N1
#SBATCH -n40
#SBATCH --mail-type=ALL
#SBATCH --mail-user=egroot
#SBATCH --mem-per-cpu=6000M
###srun -n1 modules_for_python.sh

##This script run runs "integrated_vertical_profiles.py" to make vertical cross sections of the runs to be analysed, each time combining four runs in a plot. The plot itself is maybe not very convenient, but the .csv-files generated allow with the "newplots.py" scripts for better visulation (still a too many lines though).
## Arguments required: only the fraction with which the latent heat of vaporization was mulptiplied. 
srun -n1 python integrated_vertical_profiles.py coldpool_control_ref_200m 1.0 coldpool_controlling_lve_0.6 0.6 coldpool_controlling_lve_0.8 0.8 coldpool_controlling_lve_0.9 0.9
###srun -n1 python integrated_vertical_profiles.py coldpool_control_ref_200m 1.0 coldpool_controlling_lve_1.1 1.1 coldpool_controlling_lve_1.2 1.2 coldpool_controlling_vadv_0.0 1.0
###srun -n1 python integrated_vertical_profiles.py coldpool_control_ref_200m 1.0 coldpool_controlling_vadv_0.5 1.0 coldpool_controlling_vadv_0.8 1.0 coldpool_controlling_vadv_1.5 1.0
###srun -n1 python integrated_vertical_profiles.py coldpool_control_ref_200m 1.0 coldpool_controlling_qvadv_0.8 1.0 coldpool_controlling_qvadv_1.2 1.0 coldpool_ref_res_1km 1.0
###srun -n1 python integrated_vertical_profiles.py coldpool_control_ref_200m 1.0 coldpool_cubic_res_200m 1.0 coldpool_ref_res_500m 1.0 coldpool_ref_res_1km 1.0
##srun -n1 python integrated_vertical_profiles.py coldpool_control_ref_200m 1.0 coldpool_ENS_01 1.0 coldpool_ENS_02 1.0 coldpool_ENS_03 1.0
##srun -n1 python integrated_vertical_profiles.py coldpool_control_ref_200m 1.0 coldpool_ENS_04 1.0 coldpool_ENS_05 1.0 coldpool_ENS_06 1.0
###srun -n1 python integrated_vertical_profiles.py coldpool_control_ref_200m 1.0 coldpool_ENS_07 1.0 coldpool_ENS_08 1.0 coldpool_ENS_09 1.0
###srun -n1 python integrated_vertical_profiles.py coldpool_controlling_thetaadv_0.95 1.0 coldpool_controlling_thetaadv_1.05 1.0 coldpool_ref_res_1km 1.0 coldpool_ref_res_1km 1.0
