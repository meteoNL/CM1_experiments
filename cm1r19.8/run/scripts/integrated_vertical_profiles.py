#!/usr/bin/env python3
###### -*- coding: utf-8 -*-
######"""
#####Created on Tue Nov 26 10:56:38 2019

####@author: egroot
###"""
import netCDF4 as S
import numpy as np
import matplotlib.pyplot as pl
import matplotlib
#import numpy.ma as ma
from div import D2div, MSE_inst

matplotlib.rcParams.update({'font.size': 18})

# simulations to compare
namesim2="controlling_vadv_0.8"
namesim1="controlling_lve_1.1"
namesim0="controlling_lve_0.9"
namesim="control_ref_200m"
path="/lustre/project/m2_jgu-w2w/w2w/egroot/CM1mod/cm1r19.8/run/"
#load netCDF data
test = S.Dataset(path+namesim+"/cm1out.nc",mode="r") # get netCDF data
test0=S.Dataset(path+namesim0+"/cm1out.nc",mode="r")
test1=S.Dataset(path+namesim1+"/cm1out.nc",mode="r")
test2=S.Dataset(path+namesim2+"/cm1out.nc",mode="r")

#set domain budget calculations
x1, x2, y1, y2 = -35, 60, -30, 50

    
def integration_mask(x1,x2,y1,y2,xmask,ymask):
    ''' Defines (fixed!) masked region over which vertical profiles should be calculated with this script'''
    selection=xmask>x1
    selection = selection*(xmask<x2)*(ymask>y1)*(ymask<y2)
    return selection

def prepare_data(dataset,lvef=1.0):
    '''Reads in grids of data, selects region of interest for calculations, calculates divergence and moist static energy
    and extracts time and veritcal levels to add correct tmie stamp in the plots'''
    xmask,ymask = np.meshgrid(dataset["xh"],dataset["yh"])
    selection = integration_mask(x1,x2,y1,y2,xmask,ymask)
    div = D2div(dataset,xmask,ymask)
    MSE = MSE_inst(dataset,lvef)
    lvls = len(dataset["z"])
    time_stamp=90
    time=test["time"][:]/60
    stamp=int(np.arange(len(time))[time==time_stamp])
    return selection, div, MSE, lvls, time_stamp, stamp

def returnfourzeroarrays(size):
    '''This function returns four arrays of the same shape'''
    array1,array2,array3,array4=np.zeros(size),np.zeros(size),np.zeros(size),np.zeros(size)
    return array1, array2, array3, array4

def fillarrays(size,dataset,divar,MSEarray,selectionarray):
    '''This function fills arrays with the appropriate values from the dataset for condensation (qt_cond), 
    divergence, vertical advection of horizontal momentum and change in moist static energy'''
    qvarray,divarray,momadvarray,deltaMSE=np.zeros(size),np.zeros(size),np.zeros(size),np.zeros(size)
    for i in np.arange(size):
        qvarray[i]=np.mean(-dataset["qt_cond"][0:stamp,i,:,:]*selectionarray)
        divarray[i]=np.mean(divar[stamp,i,:,:]*selectionarray)
        momadvarray[i] = np.mean(np.sqrt((dataset["ub_diag"][0:stamp,i,:,1:]*selectionarray)**2+(dataset["vb_diag"][0:stamp,i,1:,:]*selectionarray)**2))
        deltaMSE[i] = np.mean((MSEarray[stamp,i,:,:]*selectionarray)-(MSEarray[0,i,:,:]*selectionarray))   
        
        ## in the momentum-advection there is still a rather poor and crude solution to the differential grids problem above!!
    return qvarray, divarray, momadvarray, deltaMSE

#execute functions for netCDF data
selection, div, MSE, lvls, time_stamp, stamp = prepare_data(test)
selection0, div0, MSE0, lvls0, time_stamp0, stamp0 = prepare_data(test0,0.9)
selection1, div1, MSE1, lvls1, time_stamp1, stamp1 = prepare_data(test1,1.1)
selection2, div2, MSE2, lvls2, time_stamp2, stamp2 = prepare_data(test2)
#create arrays to store budget calculation values
qv_array, div_array, momadv_array, delta_MSE = returnfourzeroarrays(lvls)
qv_array0, div_array0, momadv_array0, delta_MSE0 = returnfourzeroarrays(lvls0)
qv_array1, div_array1, momadv_array1, delta_MSE1 = returnfourzeroarrays(lvls1)
qv_array2, div_array2, momadv_array2, delta_MSE2 = returnfourzeroarrays(lvls2)
#calculate profiles for both runs in comparison
qv_array, div_array, momadv_array, delta_MSE = fillarrays(lvls, test, div, MSE, selection)
qv_array0, div_array0, momadv_array0, delta_MSE0 = fillarrays(lvls0, test0, div0, MSE0, selection0)
qv_array1, div_array1, momadv_array1, delta_MSE1 = fillarrays(lvls1, test1, div1, MSE1, selection1)
qv_array2, div_array2, momadv_array2, delta_MSE2 = fillarrays(lvls2, test2, div2, MSE2, selection2)

#create plot with subplot and axes
fig = pl.figure(figsize=(8,12))
ax1 = fig.add_subplot(111)
ax2 = ax1.twiny() 

#plot the arrays of interest
ax1.plot(qv_array[:],test["z"][:],c="r", label= r"Condensation rate ($s^{-1}$)")
ax1.plot(qv_array0[:],test0["z"][:],c="r", ls="--")
ax1.plot(qv_array1[:],test1["z"][:],c="r", ls="-.")
ax1.plot(qv_array2[:],test2["z"][:],c="r", ls=":")
ax1.legend(loc="lower left", frameon=False)
ax2.plot(100000*div_array[:],test["z"][:],c="b",label=r"Divergence ($10^{-5} s^{-1}$)")
ax2.plot(100000*div_array0[:],test0["z"][:],c="b",ls="--")
ax2.plot(100000*div_array1[:],test1["z"][:],c="b",ls="-.")
ax2.plot(100000*div_array2[:],test2["z"][:],c="b",ls=":")
ax2.plot(10000*momadv_array[:],test["z"][:],c="g", label=r"Vert. adv. of hor. mom. ($0.0001$ $ms^{-2}$)")
ax2.plot(10000*momadv_array0[:],test0["z"][:],c="g",ls="--")
ax2.plot(100000*div_array1[:],test1["z"][:],c="b",ls="-.")
ax2.plot(10000*momadv_array2[:],test2["z"][:],c="g",ls=":")
ax2.plot(0.01*delta_MSE[:],test["z"][:],c="y",label=r"$\Delta$Moist static energy ($100$ $J/kg$)")
ax2.plot(0.01*delta_MSE0[:],test0["z"][:],c="y",ls="--")
ax2.plot(100000*div_array1[:],test1["z"][:],c="b",ls="-.")
ax2.plot(0.01*delta_MSE2[:],test2["z"][:],c="y",ls=":")

#### save data in csv
np.savetxt(path+namesim+"/momadv.csv",momadv_array,delimiter=",")
np.savetxt(path+namesim0+"/momadv.csv",momadv_array0,delimiter=",")
np.savetxt(path+namesim1+"/momadv.csv",momadv_array1,delimiter=",")
np.savetxt(path+namesim2+"/momadv.csv",momadv_array2,delimiter=",")

np.savetxt(path+namesim+"/div.csv",div_array,delimiter=",")
np.savetxt(path+namesim0+"/div.csv",div_array0,delimiter=",")
np.savetxt(path+namesim1+"/div.csv",div_array1,delimiter=",")
np.savetxt(path+namesim2+"/div.csv",div_array2,delimiter=",")

np.savetxt(path+namesim+"/qtend.csv",qv_array,delimiter=",")
np.savetxt(path+namesim0+"/qtend.csv",qv_array0,delimiter=",")
np.savetxt(path+namesim1+"/qtend.csv",qv_array1,delimiter=",")
np.savetxt(path+namesim2+"/qtend.csv",qv_array2,delimiter=",")

np.savetxt(path+namesim+"/delta_MSE.csv",delta_MSE,delimiter=",")
np.savetxt(path+namesim0+"/delta_MSE.csv",delta_MSE0,delimiter=",")
np.savetxt(path+namesim1+"/delta_MSE.csv",delta_MSE1,delimiter=",")
np.savetxt(path+namesim2+"/delta_MSE.csv",delta_MSE2,delimiter=",")

np.savetxt(path+namesim+"/zarray.csv",test["z"],delimiter=",")
np.savetxt(path+namesim0+"/zarray.csv",test0["z"],delimiter=",")
np.savetxt(path+namesim1+"/zarray.csv",test1["z"],delimiter=",")
np.savetxt(path+namesim2+"/zarray.csv",test2["z"],delimiter=",")

#create layout of the plots
pl.legend(loc ="upper left",frameon=False)
pl.text(40,-5,"Dotted "+str(namesim2), ha="center")
pl.text(40,-6,"Dashdotted "+str(namesim1), ha="center")
pl.text(0,-6,"Dashed "+str(namesim0), ha="center")
pl.text(0,-5,"Solid "+str(namesim), ha="center")
pl.ylim(-2.5,25)
pl.grid()
ax1.set_ylabel("z (km)")
pl.title("Mean effects after %d minutes of simulation" % time_stamp)

#display plot
#pl.show()
pl.savefig(path+"budgets_"+namesim+"_"+namesim0+"_"+namesim1+".png")
pl.clf()
