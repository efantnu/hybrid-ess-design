# Data set and simulation files
This repository contains the data set and simulation files of the paper "Sizing of Hybrid Energy Storage Systems for Inertial and Primary Frequency Control" authored by Erick Fernando Alves, Daniel dos Santos Mota and Elisabetta Tedeschi. With these files, it is possible to reproduce all the simulations and results obtained in the paper.

[![DOI](https://zenodo.org/badge/309682550.svg)](https://zenodo.org/badge/latestdoi/309682550)

# File organization
- energy_storage.slx: Simulink file containing the surrogate model of the case study presented in the section "Sizing validation"
- energy_storage_pre.m: MATLAB script that should be executed before running the Simulink model. Contains the parameters of all equipment and simulation options.
- energy_storage_post.m: MATLAB script that should be executed after running the Simulink model. It produces the datasets required for Figures 9 and 10. It also calculates the energy supplied by the battery system.  
- load-pdf.txt: dataset used to produce Figure 6. 
- results-step3-noess.txt: dataset from case 1 used to produce Figure 9. 
- results-step3.txt: dataset from case 2 used to produce Figure 9. 
- results-step12-noess.txt: dataset from case 3 used to produce Figure 10. 
- results-step12.txt: dataset from case 4 used to produce Figure 10. 
- VSCdesignpu.m: MATLAB function that designs the AC-side LC filter and DC-link capacitor of a grid-connected three-phase voltage source converter (VSC). Based on this data, it also defines optimal controller parameters for a current controller on the dq0 reference frame.

All files were created using MATLAB Simulink R2018a, the Simscape Electrical Specialized Power Systems Toolbox and the [NTNU Power Systems Library (pwrsys-matlab)](https://github.com/efantnu/pwrsys-matlab).
