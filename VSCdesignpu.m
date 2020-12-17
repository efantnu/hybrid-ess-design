%% VSCdesign.m
% Autor: Erick F. Alves
% Date: 2020-07-03
%
% This function designs the AC-side LCL filter and DC-side RC filter
% of a grid-connected thre-phase voltage source converter (VSC). Based on 
% this data, it also defines optimal controller parameters for a current 
% controller on the dq0 reference frame.
%
% Parameters defined according to:
%  - LCL filter
%  R. N. Beres, X. Wang, M. Liserre, F. Blaabjerg, and C. L. Bak, “A Review
%  of Passive Power Filters for Three-Phase Grid-Connected Voltage-Source 
%  Converters,” IEEE J. Emerg. Sel. Topics Power Electron., vol. 4, no. 1, 
%  pp. 54–69, Mar. 2016, doi: 10.1109/JESTPE.2015.2507203.
%
%  R. Pena-Alzola, M. Liserre, F. Blaabjerg, R. Sebastián, J. Dannehl, and 
%  F. W. Fuchs, “Analysis of the Passive Damping Losses in LCL-Filter-Based 
%  Grid Converters,” IEEE Trans. Power Electron., vol. 28, no. 6, 
%  pp. 2642–2646, Jun. 2013, doi: 10.1109/TPEL.2012.2222931.

%  M. Liserre, F. Blaabjerg, and A. Dell’Aquila, “Step-by-step design 
%  procedure for a grid-connected three-phase PWM voltage source converter,”
%  International Journal of Electronics, vol. 91, no. 8, pp. 445–460, 
%  Aug. 2004, doi: 10.1080/00207210412331306186.
%
% - DC Link capacitor
%  L. Malesani, L. Rossetto, P. Tenti, and P. Tomasin, “AC/DC/AC PWM 
%  converter with reduced energy storage in the DC link,” IEEE Trans. on Ind. 
%  Applicat., vol. 31, no. 2, pp. 287–292, Apr. 1995, doi: 10.1109/28.370275.
%
% - Controller tuning
%  J. A. Suul, M. Molinas, L. Norum, and T. Undeland, “Tuning of control 
%  loops for grid connected voltage source converters,” in 2008 IEEE 2nd 
%  International Power and Energy Conference, Johor Bahru, Malaysia, 
%  Dec. 2008, pp. 797–802, doi: 10.1109/PECON.2008.4762584.
%
% The function interface is the following:
%   param = Required parameters for calculation
%       Vbase = rated line rms voltage of the VSC [Vrms]
%       Sbase = rated power of the VSC [VA]
%       Vdcbase = rated DC voltage of the VSC [Vdc]
%       fbase = rated grid frequency [Hz]
%       fSwitch = switching frequency of the VSC [Hz]
%       maxDeltaI = max current ripple on the converter side [A]
%       Qlc = quality factor of the LC filter (recommended value = 3) [-]
%       maxDeltaVdc = max voltage ripple on the DC link [V]
%       maxDeltaP = max power imbalance supplied by the DC link [W]
%       kFilter = factor for measurement cut-off frequency (recommended =
%       0.1) [-]
%   designOk
%       1 = if the design was sucessful with the given parameters
%       -1 = Lac > 0.1 pu -> increase fSwitch or maxDeltaI, reduce Vdcbase
%       -2 = Clc > 0.05 pu -> increase fSwitch or maxDeltaI, reduce Vdcbase
%       -3 = fres > 0.5 * fSwitch -> reduce fSwitch or maxDeltaI, increse Vdcbase
%       -4 = fres < 0.2 * fSwitch -> increase maxDeltaI or reduce Vdcbase
%       -5 = Rlc < 0.2 / ( 2 * fres * Clc) -> increase fSwitch or maxDeltaI, reduce Vdcbase
%   filter = Filter parameters in engineering units
%       Lac = convert,er side inductance of the AC filter [H]
%       Lg = grid side inductance of the AC filter [H]
%       Clc = parallel capacitance of the AC filter [F]
%       Rlc = parallel resistance of the AC filter [Ohm]
%       fres = resonance frequency of the AC filter [Hz]
%   ctrl = PI controller parameters
%       Ta = PWM and sensors time delay [s]
%       kp = proportional gain [pu]
%       ki = integral gain [pu/s]
%       ffilt = measurement cut-off frequency [Hz]
%       kvsc = VSC gain [-]



function [designOk, filter, filterpu, ctrl] = VSCdesignpu(param)
filter = {};
filterpu = {};
ctrl = {};

%% Base values
% AC
wbase = 2*pi * param.fbase;
Zbase = param.Vbase^2 / param.Sbase;
Ibase = param.Sbase / (sqrt(3) * param.Vbase);
Lbase = Zbase / wbase;
Cbase = 1 / (wbase * Zbase);

%DC
Zdcbase = param.Vdcbase^2 / param.Sbase;
Cdcbase = 1 / (wbase * Zdcbase);



%% Converter and grid side inductances
nph = 3; % number of phases
Mmax = 0.25; % maximum parametrized current ripple
% For details on how to define Mmax, see p.28 on M. D. P. Fenili, “Estudo e 
% implementação de um filtro ativo paralelo monofásico de 8kVA,” Master
% Thesis, Federal University of Santa Catarina, Florianopolis, Brazil, 2007

filter.Lac = param.Vdcbase * Mmax / (nph * 2 * param.fSwitch * ...
    (param.maxDeltaI * Ibase) ); % Beres et al, eq (1)
filterpu.Lac = filter.Lac / Lbase;

% Check if obtained value is valid and define the grid side inductance
if filterpu.Lac >= 0.1 % Beres et al, sec II.A, constraint 3)
    designOk = -1;
    return;
else
    filterpu.Lg = 0.1 - filterpu.Lac;
end
filter.Lg = filterpu.Lg * Lbase;

%% AC filter capacitor and damping resistor

% Calculate the capacitor size - Liserre et al, eq (8).
filter.Clc = filter.Lac / Zbase^2;
filterpu.Clc = filter.Clc / Cbase;

% Check if size is within constraints - Beres et al, sec II.A, constraint 2)
if filterpu.Clc > 0.05
    designOk = -2;
    return;
end

% Calculate the resonance frequency - Liserre et al, eq (16).
c = Zbase / (2 * pi * filter.Lac);
r = filter.Lg / filter.Lac;
filter.fres = c * sqrt(1 + 1/r);
filterpu.fres = filter.fres / param.fSwitch;

% Check if resonance frequency is within range - Beres et al, sec II.B
if filter.fres > 0.5 * param.fSwitch
    designOk = -3;
    return;    
elseif filter.fres < 0.2 * param.fSwitch
    designOk = -4;
    return;
end

% Calculate the damping resistor - Beres et al, eq (8)
filter.Rlc = param.Qlc * sqrt(1 / ( (1/filter.Lac + 1/filter.Lg) * filter.Clc));
filterpu.Rlc = filter.Rlc / Zbase;

% Verify if Rlc is below maxium value - Pena-Alzola et al, eq (5)
if filter.Rlc <  1 / ( 10 * pi * filter.fres * filter.Clc)
    designOk = -5;
    return;
end


filterpu.Rac = 0.004;  % fixed value 
filter.Rac = filterpu.Rac * Zbase; 

%% DC link capacitor and resistor

% Calculate the DC-link capacitor - Malesani et al, eq (10)
filter.Cdc = param.maxDeltaT * param.maxDeltaP * param.Sbase / ...
    (2 * param.Vdcbase^2 * param.maxDeltaVdc);
filterpu.Cdc = filter.Cdc / Cdcbase;

%filterpu.Rdc = 10;
%filter.Rdc = filterpu.Rdc * Zdcbase;

%% PI controller gains
Zbasectrl = 2/3 * Zbase;
Tsamp = 1 / param.fSwitch; % Assumes Tsamp = Tswitch
ctrl.kvsc = param.Vdcbase/ (sqrt(2/3) * param.Vbase);
ctrl.ffilt = param.kFilter * filter.fres;

% Sum of time delays - Suul et al, eq (8)
ctrl.Ta = 2 / ctrl.ffilt + 0.5 * Tsamp;  

% Integral and proportional gain - Suul et al, eq (13) -> digital
Ti = filter.Lac / filter.Rac  - Tsamp/2;
ctrl.kp = filter.Rac / Zbasectrl * Ti / (2 * ctrl.Ta + Tsamp);
ctrl.ki = ctrl.kp / Ti;

% Integral and proportional gain - Suul et al, eq (11) -> continuous
%Ti = filter.Lac / filter.Rac;
%ctrl.kp = filter.Rac / Zbasectrl / (2 * ctrl.Ta);
%ctrl.ki = ctrl.kp / Ti;


designOk = 0;

return