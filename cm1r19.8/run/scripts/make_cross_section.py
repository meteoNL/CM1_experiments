#!/usr/bin/env python3
#### -*- coding: utf-8 -*-
"""
Created on Mon Nov 25 15:12:39 2019

@author: egroot
"""

import numpy as np
import matplotlib.pyplot as pl
#import numpy.ma as ma
from preparation_script import *
from div import D2div, MSE_inst

# %%
#color legend for isoline variables to be plotted, velocity and divergence
clrsvel = np.linspace(-12,12,9)
clrsdiv = np.linspace(-2e-3, 2e-3,9)

def plot_cross_sections(varname1, varname2, xmask1, zmask1, xmask2, zmask2,clrs2):
    '''This function makes some cross sections at all time steps saved in the netcdf, with varname1 and varname2 included. The xmasks and zmasks are the grids over which the cross section is plotted and with clrs2 one can define values for the value of contourlines that the second variable is plotted at'''
    fnames=[] #initialise list for names
    minimum,maximum = autoextremes(varname1) #calculate values for legend
    
    #prevent minimum and maximum to be equal
    if minimum==maximum:
        minimum = maximum - 0.001
    viewdbz=varname1[:,:,xycell,:] #extract variables at one x- or y-coordinate (defined in preparation_script.py)
    viewdbz2 = varname2[:,:,xycell,:]
    clrs = np.linspace(minimum, maximum) #create array for colors

    for i in np.arange(steps):
        # create separate .png-files for .gif-animation
        #start by clearing and initiating figure with grid
        pl.clf();
        pl.figure(figsize=(12,8))
        pl.grid()
        
        #plot the field and the second variable as isolines
        pl.contourf(xmask1,zmask1,viewdbz[i,:,:], clrs,cmap="gist_rainbow_r", vmin=minimum, vmax=maximum)
        pl.colorbar(ticks = np.linspace(minimum,maximum,11))
        ap=pl.contour(xmask2,zmask2,viewdbz2[i,:,:],clrs2,cmap="Reds")
        pl.clabel(ap)
        
        #add labels and set plotted coordinates
        pl.xlabel("x (km)")
        pl.ylabel("z (km)")
        pl.ylim(0,np.max(zmask1))
        pl.xlim(-lensim/2.,lensim/2.)
        
        #adapt title to either 2D or 3D quantity
        pl.title(namesim+" | time = %.3d"% time[i]+" min"+ " | X-section")
    
        #add full variable name and unit to legend
        fullname=str(getattr(varname1, "long_name")+" ("+varname1.units+")")
        pl.text((lensim*0.52),10, fullname, verticalalignment='center',rotation=90)
        
        #save and add filenames to list for gif
        fn = str(path+namesim+"/pngs/"+varname1.name+"%.3d" % i+".png")
        pl.savefig(fn)
        fnames+=[fn]
    #%%
    import imageio
    with imageio.get_writer(str(path+namesim+"/movie_zy_"+varname1.name+".gif"), mode='I') as writer:
        #create gif from separate .png-files
        for fn in fnames:
            image = imageio.imread(fn)
            writer.append_data(image)

#execute the above defined function for three different combinations of variables which will be plot in cross-sections            
plot_cross_sections(test["qt_cond"],div, xzmask, zxmask, xzmask, zxmask, clrsdiv)   
plot_cross_sections(test["vb_diag"],test["v"], xzmask,zxmask, xzmask,zxmask, clrsvel)   
plot_cross_sections(test["ub_diag"],test["u"], xzmaskf,zxmaskf, xzmaskf,zxmaskf, clrsvel) 

pl.clf()
