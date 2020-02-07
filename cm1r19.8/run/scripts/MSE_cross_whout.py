#!/usr/bin/env python3
###### -*- coding: utf-8 -*-
"""
Created on Mon Nov 25 15:53:06 2019

@author: egroot
"""

import numpy as np
import matplotlib.pyplot as pl
#import numpy.ma as ma
from preparation_script import *

fnames=[] #initialise list
name_figs = "cross_MSE_whout"

minimum,maximum = autoextremes(MSE)
minimum2,maximum2 =  -2e-3, 2e-3
clrs = np.linspace(minimum, maximum,51)
clrsdiv = np.linspace(minimum2,maximum2,9)
div_x=0*div[:,:,:,xcell]
MSE_x=MSE[:,:,:,xcell]
    
#define time axis

for i in np.arange(steps):
    # create separate .png-files for .gif-animation
    #clear and initiate figure with grid
    pl.clf();
    pl.figure(figsize=(12,8))
    pl.grid()
    
    # make the cross section with extra variable divergence
    pl.contourf(xzmask,zxmask,MSE_x[i,:,:], clrs,cmap="gist_rainbow_r", vmin=minimum, vmax=maximum)
    pl.colorbar(ticks = np.linspace(minimum,maximum,11))
    ap=pl.contour(xzmask,zxmask,div_x[i,:,:], clrsdiv,cmap="Reds")
    pl.clabel(ap)
    
    #add labels and set plotted coordinates
    pl.xlabel("y (km)")
    pl.ylabel("z (km)")
    pl.ylim(0,np.max(zxmask))
    pl.xlim(-lensim/2.,lensim/2.)
    
    #adapt title to either 2D or 3D quantity
    pl.title(namesim+" | time = %.3d"% time[i]+" min"+ " | X-section")

    #add full variable name and unit to legend
    fullname="Moist static energy (J/kg)"
    pl.text((lensim*0.52),10, fullname, verticalalignment='center',rotation=90)
    
    #save and add filenames to list for gif
    fn = str(path+namesim+"/pngs/"+name_figs+"%.3d" % i+".png")
    pl.savefig(fn)
    fnames+=[fn]
#%%
import imageio
with imageio.get_writer(str(path+namesim+"/movie_zy_MSE_whout.gif"), mode='I') as writer:
    #create gif from separate .png-files
    for fn in fnames:
        image = imageio.imread(fn)
        writer.append_data(image)


