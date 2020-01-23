#!/usr/bin/env python3
##### -*- coding: utf-8 -*-
"""
Created on Wed Nov 20 17:04:58 2019

@author: egroot
"""
import numpy as np

def D2div(test,xmask,ymask):
    '''Calculates two dimensional divergence based on finite differences between two neighbouring cells and assuming a regular grid'''
    du=test['u'][:,:,:,1:]-test['u'][:,:,:,:-1]
    dv=test['v'][:,:,1:,:]-test['v'][:,:,:-1,:]
    dx=1000*(xmask[0,1]-xmask[0,0])
    dy=1000*(ymask[1,0]-ymask[0,0])
    div = dv/dy+du/dx
    return div

def MSE_inst(data):
    '''Calculates instantaneous moist static energy field'''
    Cp = 1005.7
    g = 9.81
    Lv = 2501e3
    MSE = Cp*data["th"][:,:,:,:] + g*data["winterp"][:,:,:,:] + Lv*data["qv"][:,:,:,:]
    return MSE

def autoextremes(var):
    ''' this function provides nicely smoothened and rounded numbers for a legend '''
    order = round(np.log10(1/max(np.max(var),0.001))+0.5)
    fact = 10**order
    minfield = np.min(var)
    maxfield = np.max(var)
    automin = round((minfield-0.15*np.abs(minfield))*fact)/fact
    automax = round(1.15*maxfield*fact)/fact
    return automin, automax
