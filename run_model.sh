#!/bin/bash
### SBATCH recipe
#SBATCH -A m2_esm
#SBATCH -p parallel
#SBATCH -t1170
#SBATCH -N3
#SBATCH -n40
#SBATCH --mail-type=ALL
#SBATCH --mail-user=egroot
#SBATCH --mem-per-cpu=1050M

dirname="noname" 


#### Load modules: see modules_required_run.sh


##module purge
##module load data/netCDF-Fortran/4.4.4-intel-2017.02-HDF5-1.8.18


cd /lustre/miifs01/project/m2_jgu-w2w/w2w/egroot/CM1mod/cm1r19.8/run
mkdir $dirname
cd $dirname
cp ../onefile.F .
cp ../cm1.exe .
cp ../namelist.input .


srun -n120 ./cm1.exe

mkdir pngs 





