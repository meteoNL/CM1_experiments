#!/usr/bin/env python3
#### -*- coding: utf-8 -*-

import matplotlib.pyplot as pl
import netCDF4 as S
import matplotlib
import numpy as np
matplotlib.rcParams.update({'font.size': 18})
lensim = 120
path="/lustre/project/m2_jgu-w2w/w2w/egroot/CM1mod/cm1r19.8/run/"
varname = "dbz"
timeslices=np.arange(24)
fixed = 4
dfixed = 0.5

listofnames = ["cubic_res_200m","ref_res_1km","ref_res_500m"]
lvls = np.array([15,6,12])
i=0
for name in listofnames:
    lvl = lvls[i]
    i+=1
    data=S.Dataset(path+name+"/cm1out.nc",mode="r")
    xmask,ymask = np.meshgrid(data["xh"],data["yh"])
    for stamp in timeslices:
 
         pl.clf();
         pl.figure(figsize=(12,8))
         pl.grid()
    
         #plot the field 2D
         pl.contourf(xmask,ymask,data["dbz"][stamp,lvl,:,:],levels=np.arange(20,75,5),cmap="gist_rainbow_r")
         pl.colorbar()
         pl.xlabel("x (km)")
         pl.ylabel("y (km)")
         pl.ylim(-lensim/2.,lensim/2.)
         pl.xlim(-lensim/2.,lensim/2.)
         pl.title(name+" | time = %.3d"% int(stamp*5)+" min"+ " | z =  3 km")
         fullname=str(getattr(data[varname], "long_name")+" ("+data[varname].units+")")
         pl.text((lensim*0.52),10, fullname, verticalalignment='center',rotation=90)
         name_figs="reflectivity_3km_"+"%.3d" % stamp
         fn = str(path+name+"/pngs/"+name_figs+".png")
         pl.savefig(fn)
