
#!/usr/bin/env python3
#### -*- coding: utf-8 -*-
"""
Created on Wed Nov 27 16:53:46 2019

@author: egroot
"""

## imports
import netCDF4 as S
import sys
import numpy as np
from div import autoextremes, D2div, MSE_inst
import matplotlib

matplotlib.rcParams.update({'font.size': 18}) #larger font in the plots

# path to the parent directory of all runs
path="/lustre/project/m2_jgu-w2w/w2w/egroot/CM1mod/cm1r19.8/run/"
namesim = sys.argv[1]; ccf = float(sys.argv[2])#specify name of simulation and its grid resolution factor (#ncells/km) to get the correct cross-section at constant x or y
varname = "w" #variable of which the top view for level given below is plotted with read_nc_CM1.py
lvl=int(sys.argv[4]) #level at which we will look if appropriate
name_figs = "simulation_"+varname
clrsdbz = np.arange(20,75,5) # this is jusst to represent certain precip intensities by pseudoreflexivity
lensim = 120 # simulation domain length in km
xycell=int(ccf*lensim*-0.55) # x- or y-coordinate at which the cross-sections will map
test = S.Dataset(path+namesim+"/cm1out.nc",mode="r") # get netCDF data from dataset

# %%
#multiple grids are useful, make the grids available
xmask,ymask = np.meshgrid(test["xh"],test["yh"])
xzmask,zxmask = np.meshgrid(test["yh"],test["z"])
xzmaskf,zxmaskf=np.meshgrid(test["xf"],test["z"])

#compute extremes for representation in a plot legend
minimum,maximum = autoextremes(test[varname])
clrs = np.linspace(minimum, maximum)
#define time axis in minutes
steps = len(test["time"])
time = test["time"][:]/60.0

#calculate divergence and instantaneous moist static energy distribution with div.py and give result to other .py scripts
div=D2div(test,xmask,ymask)
MSE=MSE_inst(test,float(sys.argv[3]))
