This repository contains experiments done with the cloud model CM1 which is written by G. Bryan et al.
The experiments have been developed and conducted by E. Groot and Prof. Dr. H. Tost at Johannes Gutenberg University in Mainz, as part of Wavestoweather (see wavestoweather.de), during November 2019 - February 2020. The experiments are part of project A1 in phase 2 of Wavestoweather, where upscale error growth from convection to synoptic scale is studied from different perspectives. https://www.wavestoweather.de/research_areas/phase2/a1/index.html

To implement the experiments, the namelists and fortran code of CM1 has been modified by altering latent heat release and vertical advection of quantities with a keyrole in convection. Three example namelists are provided in the folder "cases_reference_namelists", which were used for three idealized case studies of upscale error growth in the vicinity of convection: supercell, squall line and ordinary multicell convection, all with run times of two hours. The Weisman-Klemp sounding is used as default with different shear profiles: very high (non-unidirectional) shear for supercell convection (60 kts/30 m/s in u-comp, in lower 6 km) and moderate (non-unidirectional) shear for ordinary multicell convection and a squall line (nearly 30 kts/15 m/s in u-comp, in lower 2.5 km, newly implemented as iwnd=12). Multicell convection is initialized with a warm bubble and squall line convection with a coldpool west of the domain centre. The winds are adapted such that winds are more or less storm relative, such that the convective event stays (near the centre) in our domain.

Note: var1-var10 have not been utilized for the purpose of experiments, but new variables and flags in the parameter-0 section have been implemented, as well as a new wind profile.  

The following components have been altered in the Fortran code and namelist. (little documentation was done so far on the actual implementation of these alterations)

* Latent heat of vaporization has been altered by -40, -20, -10, +10 and +20%. 
   Note: there is a very small inconsistency with the latent heat constants in the code, but these have been kept.

* Vertical advection of horizontal momentum, u and v: -100%, -50%, -20%, +50%. 
   Note: a diagnostic has been added in its contribution to momentum budgets, without divergent component included. In the default code 
   there was already an advection diagnostic including the divergent part.

* Vertical advection of water vapor: -20%, +20%

* Vertical advection of potential temperature: -5%, +5%.
   Note: this triggers unstable gravity waves in the stratosphere, as the restoration mechanism of the waves becomes in a Lagrangian 
   perspective an excitation mechanism.

* Grid box experiments: dependence of simulations on grid size of resolved convection. 1000x1000x500 m grid cells, 500x500x250 m grid cells, 200x200x100 m grid cells (reference), 200x200x200 m grid cells and 100x100x100 m grid cells have been used. 

* An ensemble at 200x200x100 m grid cells, where the wind profile is slightly altered. The 2.5 km shear is redistributed over a 2.37-2.54 km layer (moderate shear profile) and 5.69-6.10 km depth (supercell case with high shear).



To help me with understanding how to work with a supercomputer (in particular Mogon2) I want to thank some people for their help in setting up the runs on the machine: besides my supervisor Holger Tost also fellow Wavestoweather scientists Christopher Polster and Manuel Baumgartner (currently all at Johannes Gutenberg University). 


