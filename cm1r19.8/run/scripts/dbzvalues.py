#!/usr/bin/env python3
#### -*- coding: utf-8 -*-

# imports
import matplotlib.pyplot as pl
import netCDF4 as S
import matplotlib
import numpy as np
import sys
matplotlib.rcParams.update({'font.size': 18})

## essentials
lensim = 120 #domain size of simulation in km by km
path="/lustre/project/m2_jgu-w2w/w2w/egroot/CM1mod/cm1r19.8/run/" # path to output file folders. Parent directory of all experiments
varname = "dbz" # variable to be plotted
timeslices=np.arange(25)
fixed = 4 #maximum value of color range to be plotted
dfixed = 0.5 #interval between colors
nsecoutput = 300 # output interval in seconds

listofnames = [sys.argv[1]] ## inputs from .sh: name of simulation 
lvls = [sys.argv[2]] ## level to plot the selected variable
i=0 # run over list if list is directly defined in this script (not the case anymore)
for name in listofnames:
    lvl = int(lvls[i]) #make integer value of string input
    i+=1
    data=S.Dataset(path+name+"/cm1out.nc",mode="r") # read the output data
    xmask,ymask = np.meshgrid(data["xh"],data["yh"]) # read the grids of interest
    for stamp in timeslices: # run over output time steps
 
         # create empty figure with grid and size
         pl.clf();
         pl.figure(figsize=(12,8))
         pl.grid()
    
         #plot the field 2D and add the features of the plot
         pl.contourf(xmask,ymask,data["dbz"][stamp,lvl,:,:],levels=np.arange(20,75,5),cmap="gist_rainbow_r")
         pl.colorbar()
         pl.xlabel("x (km)")
         pl.ylabel("y (km)")
         pl.ylim(-lensim/2.,lensim/2.)
         pl.xlim(-lensim/2.,lensim/2.)

         ## time is converted to minutes!! if level changes: change z = .. km below!!
         pl.title(name+" | time = %.3d"% int(data["time"][stamp]/60)+" min"+ " | z =  3 km")

         # generate its file name, add it to the plot and save the figure
         fullname=str(getattr(data[varname], "long_name")+" ("+data[varname].units+")")
         pl.text((lensim*0.52),10, fullname, verticalalignment='center',rotation=90)
         name_figs="reflectivity_3km_"+"%.3d" % int(data["time"][stamp]/nsecoutput)
         
         # put png in subfolder pngs
         fn = str(path+name+"/pngs/"+name_figs+".png")
         pl.savefig(fn)
