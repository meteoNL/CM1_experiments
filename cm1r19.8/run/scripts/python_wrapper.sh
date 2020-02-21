#!/bin/bash
### SBATCH recipe
#SBATCH -A m2_esm
#SBATCH -p parallel
#SBATCH -t1000
#SBATCH -N1
#SBATCH -n40
#SBATCH --mail-type=ALL
#SBATCH --mail-user=egroot
#SBATCH --mem-per-cpu=3100M

### Runs a sequence of .py scripts to generate pictures and visualize the run. Required arguments: described below.

## scripts are always provided with the python script name to be run and 1. the number of grid cells per kilometre in horizontal and 2. the factor with which lve was mulptiplied (even if 1.0) and 3. the model level at which we need near-tropopause vertical velocity (or reflectivity)

srun -n1 python MSE_cross_whout.py bubble_control_ref_200m 5.0 1.0 115
srun -n1 python MSE_cross.py bubble_control_ref_200m  5.0 1.0 115
srun -n1 python read_nc_CM1.py bubble_control_ref_200m 5.0 1.0 115
srun -n1 python make_cross_section.py bubble_control_ref_200m 5.0 1.0 115
srun -n1 python wvalues.py bubble_control_ref_200m 115
srun -n1 python dbzvalues.py bubble_control_ref_200m 30


srun -n1 python MSE_cross_whout.py bubble_ENS_01 5.0 1.0 115
srun -n1 python MSE_cross.py bubble_ENS_01 5.0 1.0 115
srun -n1 python read_nc_CM1.py bubble_ENS_01 5.0 1.0 115
srun -n1 python make_cross_section.py bubble_ENS_01 5.0 1.0 115
srun -n1 python wvalues.py bubble_ENS_01 115
srun -n1 python dbzvalues.py bubble_ENS_01 30

srun -n1 python MSE_cross_whout.py bubble_ENS_02 5.0 1.0 115
srun -n1 python MSE_cross.py bubble_ENS_02 5.0 1.0 115
srun -n1 python read_nc_CM1.py bubble_ENS_02 5.0 1.0 115
srun -n1 python make_cross_section.py bubble_ENS_02 5.0 1.0 115
srun -n1 python wvalues.py bubble_ENS_02 115
srun -n1 python dbzvalues.py bubble_ENS_02 30

srun -n1 python MSE_cross_whout.py bubble_ENS_03 5.0 1.0 115
srun -n1 python MSE_cross.py bubble_ENS_03 5.0 1.0 115
srun -n1 python read_nc_CM1.py bubble_ENS_03 5.0 1.0 115
srun -n1 python make_cross_section.py bubble_ENS_03 5.0 1.0 115
srun -n1 python wvalues.py bubble_ENS_03 115
srun -n1 python dbzvalues.py bubble_ENS_03 30

srun -n1 python MSE_cross_whout.py bubble_ENS_04 5.0 1.0 115
srun -n1 python MSE_cross.py bubble_ENS_04 5.0 1.0 115
srun -n1 python read_nc_CM1.py bubble_ENS_04 5.0 1.0 115
srun -n1 python make_cross_section.py bubble_ENS_04 5.0 1.0 115
srun -n1 python wvalues.py bubble_ENS_04 115
srun -n1 python dbzvalues.py bubble_ENS_04 30

srun -n1 python MSE_cross_whout.py bubble_ENS_05 5.0 1.0 115
srun -n1 python MSE_cross.py bubble_ENS_05 5.0 1.0 115
srun -n1 python read_nc_CM1.py bubble_ENS_05 5.0 1.0 115
srun -n1 python make_cross_section.py bubble_ENS_05 5.0 1.0 115
srun -n1 python wvalues.py bubble_ENS_05 115
srun -n1 python dbzvalues.py bubble_ENS_05 30

srun -n1 python MSE_cross_whout.py bubble_ENS_06 5.0 1.0 115
srun -n1 python MSE_cross.py bubble_ENS_06 5.0 1.0 115
srun -n1 python read_nc_CM1.py bubble_ENS_06 5.0 1.0 115
srun -n1 python make_cross_section.py bubble_ENS_06 5.0 1.0 115
srun -n1 python wvalues.py bubble_ENS_06 115
srun -n1 python dbzvalues.py bubble_ENS_06 30

srun -n1 python MSE_cross_whout.py bubble_ENS_07 5.0 1.0 115
srun -n1 python MSE_cross.py bubble_ENS_07 5.0 1.0 115
srun -n1 python read_nc_CM1.py bubble_ENS_07 5.0 1.0 115
srun -n1 python make_cross_section.py bubble_ENS_07 5.0 1.0 115
srun -n1 python wvalues.py bubble_ENS_07 115
srun -n1 python dbzvalues.py bubble_ENS_07 30


srun -n1 python MSE_cross_whout.py bubble_ENS_08 5.0 1.0 115
srun -n1 python MSE_cross.py bubble_ENS_08 5.0 1.0 115
srun -n1 python read_nc_CM1.py bubble_ENS_08 5.0 1.0 115
srun -n1 python make_cross_section.py bubble_ENS_08 5.0 1.0 115
srun -n1 python wvalues.py bubble_ENS_08 115
srun -n1 python dbzvalues.py bubble_ENS_08 30

srun -n1 python MSE_cross_whout.py bubble_ENS_09 5.0 1.0 115
srun -n1 python MSE_cross.py bubble_ENS_09 5.0 1.0 115
srun -n1 python read_nc_CM1.py bubble_ENS_09 5.0 1.0 115
srun -n1 python make_cross_section.py bubble_ENS_09 5.0 1.0 115
srun -n1 python wvalues.py bubble_ENS_09 115
srun -n1 python dbzvalues.py bubble_ENS_09 30





