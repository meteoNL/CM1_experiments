#!/usr/bin/env python3
#### -*- coding: utf-8 -*-
####"""
####Created on Fri Oct 05 08:12:20 2018

###@author: Edward and Chenxi

###This script is a modification of a model made in my Master in Utrecht during the course Simulation (Simulation of Ocean and Atmosphere & Climate, SOAC), in collaboration with Chenxi Qiu in 2018. In this implementation it shows a "skew-T" type of diagram of the SE boundary of the model domain (or other cells if these are selected) at initial conditions, including wind barbs, vertical height in altitude and common pressure levels. A simple microphysics and mixing representation could even be switched on. The initial parcel is pushed upward at 6 m/s (or otherwise if winit is modified). 

### Since convection evolves with time explicitly, for different applications tend (ending time of the simulation) should be modified. 

## Original source code of the "SOAC" project: https://github.com/meteoNL/CloudParcelModel_SOACproject
###"""

namesim="control_ref_200m" ## simulation name to be visualised
path="/lustre/project/m2_jgu-w2w/w2w/egroot/CM1mod/cm1r19.8/run/coldpool_" ## path to the simulation

#imports
import numpy as np
import matplotlib.pyplot as pl
import netCDF4 as S
import matplotlib

matplotlib.rcParams.update({'font.size': 21}) 
## read netCDF library
test=S.Dataset(path+namesim+"/cm1out.nc",mode="r")

#input of the model
#constants
g=9.81 #gravitational acceleration
cp=1005. #specific heat per kilogram of dry air
T0=273.15 #zero Celsius Kelvin reference temperature
Rv=461.5 #gas constant water vapor
Rd=287.05 #gas constant dry air
Lf = 3.35e5 #latent heat of fusion
es0=610.78 #reference saturation vapor pressure
T1=273.16 #tripel point of water
T2=235. #upper bound for removing water vapor into ice
es1=611.20 #saturation vapor pressure over ice at tripel point
epsilon=0.622 #molar mass ratio water and dry air
Ka = 2.4e-2 #Thermal conductivity of air
rhoi = 700. #density of ice cristal, kg/m3

#pseudoconstants
def chi(p): #diffusivity of water vapor
    return 2.21/p
def A(T): #see Rotstayn (2000)
    return Ls(T)/Ka/T*(Ls(T)/(Rv*T)-1)
def Lv(T):#latent heat of vaporization water
    return (2.501 - 2.361e-3*(T-T0))*1e6
def Ls(T): #latent heat of sublimation water
    return Lf+ Lv(T)

#time space
tend=700. #end of the simulation, s; 5 hours
dt=0.1 #time step, s
t1=np.linspace(0.0,tend,int(tend/dt)) 
dz=0.1 #vertical step for pressure initiation of parcel

#initial parcel characterstics
Riniteq=10. #initial CP radius
parcel_bottom=875. #initial condition
ntop=0.0 #for parcel top; if exactly spherical n=2.0
parcel_top=parcel_bottom+ntop*Riniteq
Tdis=0 #temperature disturbance = initial condition
wvdis=0 #water vapor disturbance = initial condition
winit=6. #initial condition vertical velocity

#parameters 
gamma=0.5 #induced relation with environmental air, inertial
#mu=0.9e-4 #entrainment of air: R.A. Anthes (1977) gives 0.183/radius as its value
tau_cond = 5. #time scale for condensation, s
tau_evap = 5. #time scale for evaporation, s
tau_warmpc = 90.*60 #time scale for the formation of warm precipitation, s, 1000 s in Anthes (1977); the idea appears to be from Kessler (1969)
tau_coldpc = 12.*60 #time scale for the formation of cold precipitation, 700 s in ECMWF doc mentioned
C_evap=1400. #rate constant for evaporation
wLthres=4.5e-4 # threshold for precip based on ECMWF documentation; 5e-4 in Anthes (1977)
withres=wLthres #threshold for precip form from ice
Cconv = 10. #assumed constant for increased rate in deposition in convective clouds compared to shallow stratiform clouds
Cinvr=0.0
mu0=0e-5
#entrainment parameterization
def mu_calc(R):
    #this is based on reading in the Pruppacher & Klett, 2010, chapter 12
    return Cinvr/R+mu0 #to switch off if no entrainment
    #return 0.00 #to switch on if no entrainment

#profile drying constants experiment , 1.00 in any layer means no drying and zint is the interface between the first and second layer
Cdry=np.array([1.00,1.00])
zint=2000.0
i=0

#%%
#read background data from 20090526_00z_De_Bilt
#fn='20100826_12z_Essen_mod.txt'
#f=open(fn,'r')

## netCDF data to be read from specified gridcells, default SE most region. Pressure (p_d), height (z), potential temperature and water vapor mixing ratio.
p_d = test["prs"][0,:,-1,-1]
z = 1000*test["z"][:]#np.array([])
T = test["th"][0,:,-1,-1]-g/cp*z
wv = test["qv"][0,:,-1,-1]
#for line in f:
#    line=line.split(';')
#    p_d = np.append(p_d, float(line[1])*100.) #read pressure and convert to Pa
#    z = np.append(z, float(line[2])) #read height in meters
#    if z[-1] > zint:
#        i=1
#    T = np.append(T, float(line[3])+T0) #read temperature and convert to Kelvin
#    wv = np.append(wv, Cdry[i]*float(line[6])/1000.) #read water vapor mixing ratio and convert to kg/kg
#f.close()

#%%
#arrays for data in the environment and in the parcel, p:parcel env:environment
sat = np.zeros(len(t1))
zp = np.zeros(len(t1))
Tp = np.zeros(len(t1))
w = np.zeros(len(t1))
wvp = np.zeros(len(t1))
wvenv = np.zeros(len(t1))
p = np.zeros(len(t1))
Tenv = np.zeros(len(t1))
wL = np.zeros(len(t1))
wi = np.zeros(len(t1))
total_prec = np.zeros(len(t1))
sat = np.zeros(len(t1))
C = np.zeros(len(t1))
E = np.zeros(len(t1))
total_water=np.zeros((len(t1)))
Rp = np.zeros(len(t1))
mup = np.zeros(len(t1))
Mp = np.zeros(len(t1))

#%% envirmental profiles used
#interpolate T and wv profiles, linear interpolation y=a*x+b where a = d/dz of the respective variable and b is the reference value that was measured
def find_nearest(array, value):
    array = np.asarray(array)
    idx = (np.abs(array - value)).argmin()
    return idx

def Tenvcalc(h):
    if h<=z[0]:
        Tenv = T[0]
    elif h>=z[-1]:
        Tenv = T[-1]
    else: 
        i = find_nearest(z,h)
        if h == z[i]:
            Tenv = T[i]
        elif h > z[i]:
            dTdz=(T[i+1]-T[i])/(z[i+1]-z[i])
            Tenv = T[i]+(h-z[i])*dTdz
        else:
            dTdz=(T[i]-T[i-1])/(z[i]-z[i-1])  
            Tenv = T[i]+(h-z[i])*dTdz
    return Tenv

def wvenvcalc(h):
    if h<=z[0]:
        wvenv = wv[0]
    elif h>=z[-1]:
        wvenv = wv[-1]
    else:  
        i = find_nearest(z,h)
        if h == z[i]:
            wvenv = wv[i]
        elif h > z[i]:
            dwvdz=(wv[i+1]-wv[i])/(z[i+1]-z[i])
            wvenv = wv[i]+(h-z[i])*dwvdz
        else:
            dwvdz=(wv[i]-wv[i-1])/(z[i]-z[i-1])  
            wvenv = wv[i]+(h-z[i])*dwvdz
    return wvenv
def Tvcalc(T,wv):
    return T*(1+(wv)/epsilon)/(1+wv) 
def p0(zloc,dz):
    #locate layer in which parcel is
    i=0
    while zloc > z[i+1]:
        i+=1
        
    #get properties at the base of this layer (lower bound, pressure & height) and layer means (temp & water vapor)    
    zval=z[i]
    pref=p_d[i]

    while zval < zloc:
        #integrate hydrostatic equilibrium with EF and given dz
        zval+=0.5*dz
        Tloc=Tenvcalc(zval)
        wvloc=wvenvcalc(zval)
        Tvloc=Tvcalc(Tloc,wvloc)#*(1+(wvloc)/epsilon)/(1+wvloc) #from Aarnouts lecture notes
        rho = pref/(Rd*Tvloc)
        dpdz=-rho*g
        pref+=dpdz*dz
        zval+=0.5*dz
    return pref

#%%
#initial conditions
def meanenvcalc(bottom,top,name):
    levels=np.linspace(bottom,top+1e-12,51)
    values=np.zeros(len(levels))
    for i in range(len(levels)):
        if name=='Tenv':
            values[i]=Tenvcalc(levels[i])
        elif name=='wvenv':
            values[i]=wvenvcalc(levels[i])
    return np.mean(values)

#put initial conditions provided above in arrays of result values    
zp[0] = parcel_bottom+0.5*(parcel_top-parcel_bottom) #initial height of parcel, m
Tp[0] = meanenvcalc(parcel_bottom,parcel_top,'Tenv')+Tdis #initial temperature of parcel, K
w[0] = winit #initial velocity of parcel, m/s
wvp[0] = meanenvcalc(parcel_bottom,parcel_top,'wvenv')+wvdis #mixing ratio of water vapor of parcel, kg/kg
wL[0] = 0. #cloud content
total_prec[0] = 0.
p[0] = p0(zp[0],dz)

#%%
#differential equations
def dwdt(w,Tp,Tenv,wvp,wvenv,wL): 
    Tvp=Tvcalc(Tp,wvp)
    Tvenv=Tvcalc(Tenv,wvenv)
    return 1./(1.+gamma)*(g*((Tvp-Tvenv)/Tvenv-wL-wi[i])-mu*abs(w)*w)

def dTpdt(w,Tp,Tenv,zp,C,E,dwidt):
    return -g*w/cp-mu*abs(w)*(Tp-Tenv)+Lv(Tp)/cp*(C-E)+dwidt*Lf/cp

def dwvpdt(w,wvp,wvenv,C,E):
    return -mu*(wvp-wvenv)*abs(w)-C+E

def dpdt(rho,w):
    return -rho*g*w

def dwLdt(w,C,E,wL):
    return C-E-mu*wL*abs(w)

def dmdt(mu,w,m):
    return mu*np.abs(w)*m

def func(phi,procarg,rho):#C,E,warm_precip,rho,Tenv,wvenv,t):#phi = [p,w,zp,Tp,wvp,wL]
    #extract values
    m,w,zp,Tp,wvp,wL=phi[0],phi[2],phi[3],phi[4],phi[5],phi[6]
    C,E,Tenv,wvenv,dwidt=procarg[0],procarg[1],procarg[2],procarg[3],procarg[4]

    #do the diff eqs
    dm=dmdt(mu,w,m)*dt
    dp=dpdt(rho,w)*dt
    dw=dwdt(w,Tp,Tenv,wvp,wvenv,wL)*dt
    dzp=w*dt
    dTp=dTpdt(w,Tp,Tenv,zp,C,E,dwidt)*dt
    dwvp=dwvpdt(w,wvp,wvenv,C,E)*dt
    dwL=dwLdt(w,C,E,wL)*dt
    return np.array([dm,dp,dw,dzp,dTp,dwvp,dwL])

#%% thermodynamic equilibria over water/ice surfaces
#equations from lecture notes by Van Delden (2017/2018) retrieved from http://www.staff.science.uu.nl/~delde102/dynmeteorology.htm; fromUniversity of North Carolina lecuture slides retrieved from http://www.atms.unca.edu/cgodfrey/courses/atms320/ppt/hygrometry.pdf and Wallace and Hobbs (2006)
def escalc(T):
    diffT=(1./T0-1./T)
    difflnes=Lv(T)/Rv*diffT
    lnes=difflnes+np.log(es0)
    es=np.exp(lnes)
    return es

def wvscalc(T,p):#calculation of water vapor saturation mixing ratio
    es=escalc(T)
    wvsat=epsilon*(es/(p-es))
    return wvsat

def esicalc(T,p):#calculation of water vapor saturation mixing ratio
    diffT=(1./T1-1./T)
    difflnesi=Ls(T)/Rv*diffT
    lnesi=difflnesi+np.log(es1)
    esi = np.exp(lnesi)
    return esi

#%%
#processes: phase changes
def condensation(wv,wvs):
    if wv > wvs:
        return (wv-wvs)*(1-np.exp(-dt/tau_cond))/dt
    else:
        return 0.00

def evaporation(wv,wvs,wL):
    #if wvs > wv and wL>0:
    #    return C_evap*wL*(wvs-wv)*((1-np.exp(-dt/tau_evap)))/dt
    #else:
    return 0.00

#deposition of cloud water to solid phase: Rotstayn et al 2000, multiplied by Cconv
def B(T,p):
    return Rv*T*chi(p)*esicalc(T,p)    
def Ni(T,p):
    return 1e3*np.exp(12.96*(escalc(T)-esicalc(T,p))/esicalc(T,p)-0.639)
def cvd(T,p,rho):
    return Cconv*7.8*(((Ni(T,p)/rho)**(2./3))*(escalc(T)-esicalc(T,p)))/(rhoi**(1./3)*(A(T)+B(T,p))*esicalc(T,p))
def Wi_depmeltfreez(T,p,rho,wL,dt):
    #if T > T2 and T < T0:
    #    result=(2./3*cvd(T,p,rho)*dt+wi[i]**(2./3))**(3./2)
    #    if result < wL:
    #        return result
    #    else:
    #        return wi[i]+wL
    #elif T < T2:
    #    return wi[i]+wL
    #else:
    return 0.00

#%% precipitation processes
#warm precipitation (mainly autoconversion simulation)
def warm_precip(wL,Tp):
    #if wL > wLthres:
    #    return (wL-wLthres)*(1-np.exp(-dt/tau_warmpc))
    #else:
    return 0.0

#cold precipitation
def cold_precip(wL,wi):
    #result1=(wi-withres)*(1-np.exp(-dt/tau_coldpc))
    #if wi > withres:
    #    return result1
    #else:
    return 0.00
    
#%%Integration procedure
t=t1[0]
Tenv[0] = Tenvcalc(zp[0])
wvenv[0] = wvenvcalc(zp[0]) 
sat[0] = wvp[0]/wvscalc(Tp[0],p[0])
C[0] = condensation(wvp[0],wvscalc(Tp[0],p[0]))
E[0] = evaporation(wvp[0],wvscalc(Tp[0],p[0]),0)
Rp[0] = Riniteq
mup[0] = mu_calc(Rp[0])
Tv = Tvcalc(Tp[0],wvp[0])
rho = p[0]/(Rd*Tv) #ideal gas law
Mp[0] = (4./3*Rp[0]**3)*rho
dwidt=0.
for i in range(len(t1)-1): 
    #do the gass law and hydrostatic equilibrium to calculate pressure and saturation
    Tv = Tvcalc(Tp[i],wvp[i])
    rho = p[i]/(Rd*Tv) #ideal gas law
    Rp[i]=(3./4*Mp[i]/rho)**(1./3)
    mu=mu_calc(Rp[i])
    mup[i]=mu
    #Runge- Kutta numerical scheme 
    processargs=np.array([C[i],E[i],Tenv[i],wvenv[i],dwidt])
    phi=np.array([Mp[i],p[i],w[i],zp[i],Tp[i],wvp[i],wL[i]])
    k1,k2,k3,k4=np.zeros(7),np.zeros(7),np.zeros(7),np.zeros(7)
    k1[:]=func(phi, processargs,rho)
    k2[:]=func((phi+0.5*k1), processargs,rho)
    k3[:]=func((phi+0.5*k2), processargs,rho)
    k4[:]=func((phi+k3), processargs,rho)

    #update values and save them in resulting array that includes time
    phi=phi+np.array((1./6)*(k1+2*k2+2*k3+k4),dtype='float64')
    t=t1[i+1]
    Mp[i+1]=phi[0]
    p[i+1]=phi[1]
    w[i+1]=phi[2]
    zp[i+1]=phi[3]
    Tp[i+1]=phi[4]
    wvp[i+1]=phi[5]  
    wL[i+1]=phi[6]
    
    #update parcel environment
    Tenv[i+1] = Tenvcalc(zp[i+1])
    wvenv[i+1] = wvenvcalc(zp[i+1]) 
    
    #calculate saturation values
    wvs = wvscalc(Tp[i+1],p[i+1]) #water vapor saturation mixing ratio 
    sat[i+1] = wvp[i+1]/wvs    
    
    #then do condencsation, evaporation, freezing, melting, deposition/Findeisen-Wegener-Bergeron process
    C[i+1]=condensation(wvp[i+1],wvs)
    E[i+1]=evaporation(wvp[i+1],wvs,wL[i+1])
    wi[(i+1)]=Wi_depmeltfreez(Tp[i+1],p[i+1],rho,wL[i+1],dt)
    dwidt=(wi[i+1]-wi[i])/dt
    dwi=(wi[i+1]-wi[i])
    wL[i+1]=wL[i+1]-dwi
    
    #precipitation process of the clouds and remove the cold precip from ice parcels
    warm_prec=warm_precip(wL[i+1],Tp[i+1])
    cold_prec=cold_precip(wL[i+1],wi[i+1])
    wi[i+1]=wi[i+1]-cold_prec
    wL[i+1]=wL[i+1]-warm_prec
    total_prec[i+1]=total_prec[i]+warm_prec+cold_prec #update total precipitation
#integrate precipitation and divide by areal extent
total_prec_mm=np.round(np.dot((total_prec[1:]-total_prec[:-1]),Mp[:-1])/(np.pi*Rp[-2]**2),2)    
#%% visualization of results
#plot temerature profile
Tgamma=0.0050 #skew T visualzation constant
pdef=np.array([[85000],[70000],[50000],[30000],[20000]])
def calcplevel(ps=pdef):
    res=np.zeros(np.shape(ps))
    for i in np.arange(len(ps)):
        res[i]=zp[abs(p-ps[i]).argmin()]
    return res
        

def Tdew(T,wv,p):
    #approximate dew point working above -50 degrees C, calculation retrieved from http://irtfweb.ifa.hawaii.edu/~tcs3/tcs3/Misc/Dewpoint_Calculation_Humidity_Sensor_E.pdf
    Tdew=np.ones(len(T))
    wvsloc=wvscalc((T+T0),p)
    
    #prevent run towards minus infinity for the log number
    wv[wv==0.]=1e-7
    
    #continue calculations
    relhum=wv[wv>0.]/wvsloc
    relhum=relhum*100.
    H=(np.log10(relhum)-2.)/0.4343+(17.62*T)/(243.12+T)
    Tdew=243.12*H/(17.62-H)
    return Tdew
xbarbs=304
knms=0.5144
everyW=4
def plotbarbs(u,v,z,everyW):
    for i in np.arange(0,len(u),everyW):
        if z[i]< 16:
            pl.barbs(xbarbs,z[i]*1000,u[i]/knms,v[i]/knms)
plevelsplot=calcplevel()
xticks=np.array([])
z_plot=np.arange(0,18000,1000)
pl.figure(figsize=(12,8))
for i in range(183,310,5):
    pl.plot(i*np.ones(len(z_plot))+Tgamma*z_plot,z_plot,c=(0.6,0.6,0.6),lw=0.5)
    if i > 270 and i < 310:
        xticks=np.append(xticks,np.array([i]))
for zh in range(2,17,2):
    pl.plot(np.array([260,320]),np.array([zh*1000,zh*1000]),lw=0.5,c=(0.6,0.6,0.6),ls=":")
pl.plot((Tp+Tgamma*zp),zp,c='r',label='Tparcel')
plotbarbs(test["u"][0,:,0,0],test["v"][0,:,0,0],test["z"],everyW)
dew=(Tdew((T-T0),wv,p_d)+Tgamma*z+T0)
pl.plot(dew,z,c='b',label='Tdew',ls='--')
for i in np.arange(len(pdef)):
    pl.text(311,plevelsplot[i],str(int(pdef[i]/100)))
pl.text(314,5000,"Pressure (hPa)",rotation=90)
pl.plot((T+Tgamma*z),z,c='g',label='Tenv')
pl.title("Initial conditions plot")
pl.xlim(270,310)
pl.xticks(xticks,(xticks-273))
pl.legend(loc=3)
pl.ylim(0,16000)
pl.xlabel('Temperature (degrees Celsius)')
pl.ylabel('Height (m)')
pl.savefig(path+namesim+"/"+"initial_new.png")

##rain event evolution
#pl.figure(figsize=(12,8))
#pl.title(fn[:-4]+' precipitation produced by CPM')
#pl.plot(t1,total_prec)
#pl.xlabel('Time (s)')
#pl.ylabel('Cumulative precipitation mixing ratio (g/g)')
#pl.grid()
#maxaxis=np.round(0.5+1000*total_prec[-1]*1.2,0)/1000.
#pl.ylim(0,maxaxis)
#pl.xlim(0,np.max(t1))
#pl.text(0,-.16*maxaxis,'Areal mean total precipitation: '+str(total_prec_mm)+' mm')
#pl.show()
#
##cloud composition as function of temperature
#pl.figure(figsize=(12,8))
#pl.plot(wL,Tp,label='Cloud liquid water mixing ratio')
#pl.plot(wi,Tp,label='Cloud ice mixing ratio')
#pl.plot(np.ones(len(Tp))*wLthres,Tp,ls='--',c='b',label='Warm precipitation threshold')
#pl.plot(np.ones(len(Tp))*withres,Tp,ls=':',c='r',label='Cold precipitation threshold')
#pl.legend(loc=1)
#pl.title('Cloud content and temperature')
#pl.xlabel('Mixing ratio (g/g)')
#pl.ylabel('Temperature (K)')
#pl.xlim(0,np.max(wv))
#pl.ylim(np.min(np.min(Tp)),np.max(Tp))
#pl.grid()
#pl.show()
#
##cloud composition as function of time
#pl.figure(figsize=(12,8))
#pl.plot(t1,wL,label='Cloud liquid water mixing ratio')
#pl.plot(t1,wi,label='Cloud ice mixing ratio')
#pl.plot(t1,wi+wL,label='Ice + liquid water mixing ratio',c=(0.4,0.4,0.4))
#pl.plot(t1,np.ones(len(Tp))*wLthres,ls='--',c='b',label='Warm precipitation threshold')
#pl.plot(t1,np.ones(len(Tp))*withres,ls=':',c='r',label='Cold precipitation threshold')
#pl.legend(loc=1)
#pl.title('Cloud content and temperature')
#pl.ylabel('Mixing ratio (g/g)')
#pl.xlabel('time (s)')
#pl.ylim(0,np.max(wv))
#pl.xlim(0,np.max(t1))
#pl.grid()
#pl.show()
#
##velocity of the parcel
#pl.figure(figsize=(12,8))
#pl.title('Vertical velocity evolution')
#pl.plot(t1,w)
#pl.xlabel('time (s)')
#pl.ylabel('w (m/s)')
#pl.xlim(0,np.max(t1))
#maxvel=np.round(1.1*np.max(np.abs(w))+0.5)
#pl.ylim(-maxvel,maxvel)
#pl.text(0,-1.36*maxvel,r'Effective maximum kinetic energy: '+str(np.round(0.5*np.max(w**2),1))+' m$^2$/s$^2$')
#pl.grid()
#pl.show()
