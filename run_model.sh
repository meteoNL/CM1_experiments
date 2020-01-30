#!/bin/bash

#SBATCH -A m2_esm
#SBATCH -p parallel
#SBATCH -t1170
#SBATCH -N3
#SBATCH -n40
#SBATCH --mail-type=ALL
#SBATCH --mail-user=egroot
#SBATCH --mem-per-cpu=1100M

dirname="no_sim"


#### Load modules

#####module load compiler/ifort/2018.3.222-GCC-6.3.0
#####module load data/netCDF-Fortran/4.4.4-intel-2018.03
#####module load mpi/impi/2018.3.222-iccifort-2018.3.222-GCC-6.3.0

##module purge
##module load data/netCDF-Fortran/4.4.4-intel-2017.02-HDF5-1.8.18

## compile the model as in model compiler description
## cd /lustre/miifs01/project/m2_jgu-w2w/w2w/egroot/CM1/cm1r19.8/src
##make clean
##make

# cd ../run/

cd /lustre/miifs01/project/m2_jgu-w2w/w2w/egroot/CM1mod/cm1r19.8/run
mkdir $dirname
cd $dirname
cp ../onefile.F .
cp ../cm1.exe .
cp ../namelist.input .

##test -f cm1.exe && ./cm1.exe
##test -f cm1.exe || echo "The file is not there. Cannot run."

srun -n120 ./cm1.exe

##cp cm1out.nc $dirname
##mv cm1out_stats.nc $dirname
##cp onefile.F $dirname
##cp cm1.exe $dirname
##cp namelist.input $dirname 





