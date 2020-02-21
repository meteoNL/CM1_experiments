#!/usr/bin/env python3
###### -*- coding: utf-8 -*-
"""
Created on Thu Nov 14 17:29:45 2019

@author: egroot
"""
#imports
import matplotlib.pyplot as pl
from preparation_script import *
#import numpy.ma as ma

fnames=[] #initialise list

## distinction for legend between integrated/surface and 3D quantities!
if lvl == "vert":
    viewdbz=test[varname][:,:,:]
else: 
    viewdbz=test[varname][:,lvl,:,:]
    maxlvl = len(test[varname][0,:,0,0])

for i in np.arange(steps):
    # create separate .png-files for .gif-animation
    #clear plot, make figue and initiate grid
    pl.clf();
    pl.figure(figsize=(12,8))
    pl.grid()
    
    #plot the field 2D
    pl.contourf(xmask,ymask,viewdbz[i,:,:], clrs,cmap="gist_rainbow_r",vmin=minimum,vmax=maximum)
    pl.colorbar(ticks = np.linspace(minimum,maximum,11))
    
    #add labels and set plotted coordinates
    pl.xlabel("x (km)")
    pl.ylabel("y (km)")
    pl.ylim(-lensim/2.,lensim/2.)
    pl.xlim(-lensim/2.,lensim/2.)
    
    #adapt title to either 2D or 3D quantity
    if lvl != "vert":
        pl.title(namesim+" | time = %.3d"% time[i]+" min"+ " | level = "+str(lvl)+"/"+str(maxlvl))
    else:
        pl.title(namesim+" | time = %.3d"% time[i]+" min")
        
    #add full variable name and unit to legend
    fullname=str(getattr(test.variables[varname], "long_name")+" ("+test.variables[varname].units+")")
    pl.text((lensim*0.52),0, fullname, verticalalignment='center',rotation=90)
    
    #save and add filenames to list for gif
    fn = str(path+namesim+"/pngs/"+name_figs+"%.3d" % i+".png")
    pl.savefig(fn)
    fnames+=[fn]
#%%
import imageio
with imageio.get_writer(str(path+namesim+"/movie"+varname+".gif"), mode='I') as writer:
    #create gif from separate .png-files
    for fn in fnames:
        image = imageio.imread(fn)
        writer.append_data(image)


