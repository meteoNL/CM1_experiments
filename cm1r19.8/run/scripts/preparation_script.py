
#!/usr/bin/env python3
#### -*- coding: utf-8 -*-
"""
Created on Wed Nov 27 16:53:46 2019

@author: egroot
"""
import netCDF4 as S
import numpy as np
from div import autoextremes, D2div, MSE_inst
import matplotlib

matplotlib.rcParams.update({'font.size': 18}) #larger font in the plots

path="/lustre/project/m2_jgu-w2w/w2w/egroot/CM1mod/cm1r19.8/run/"
namesim = "controlling_MSEadv_0.995"; ccf = 5.000 #specify name of simulation and its factor to get the correct cross-section at constant x
varname = "w" #variable of which the top view for level given below is plotted with read_nc_CM1.py
lvl=115 #level at which we will look if appropriate
name_figs = "simulation_"+varname
clrsdbz = np.arange(20,75,5) # this is jusst to represent precip intensities by pseudoreflexivity
lensim = 120 # simulation domain length in km
xcell=int(ccf*lensim*-0.55) # x-coordinate at which the cross-sections will map
test = S.Dataset(path+namesim+"/cm1out.nc",mode="r") # get netCDF data

# %%
#multiple grids are useful
xmask,ymask = np.meshgrid(test["xh"],test["yh"])
xzmask,zxmask = np.meshgrid(test["yh"],test["z"])
xzmaskf,zxmaskf=np.meshgrid(test["yf"],test["z"])

#compute extremes for representation in a plot legend
minimum,maximum = autoextremes(test[varname])
clrs = np.linspace(minimum, maximum)
#define time axis
steps = len(test["time"])
time = np.linspace(0,lensim,steps)

#calculate divergence and instantaneous moist static energy distribution
div=D2div(test,xmask,ymask)
MSE=MSE_inst(test,1.0)
