clearvars;

%% Script Parameters
caseNumber = 1;  % Select the case number from the paper

%% Grid parameters
grid.fn = 60;       % Rated frequency [Hz]
grid.UB1 = 675;     % Rated line voltage at converter output [Vrms]
grid.UB2 = 11e3;    % Rated line voltage at PCC [Vrms]
grid.Sb = 70e6;     % Base power [VA]
grid.rss = 0.02;    % Maximum steady-state frequency deviation [pu]


%% Grid-Side Converter (GSC) parameters

% Base values
gsc.fbase = grid.fn;    % Frequency [Hz]
gsc.Sbase = 9.65e6;     % Apparent power [VA]
gsc.Vbase = grid.UB1;   % Line voltage [Vrms]
gsc.Vdcbase = 1500;     % dc-link voltage [Vdc]

% Design parameters in pu
gsc.fSwitch = grid.fn*90;           % VSC switch frequency [Hz]
gsc.maxDeltaI = 0.25;               % Max current ripple on the converter side inductance
gsc.Qlc = 0.3;                      % Damping factor of the LCL filter (recommended = 0.3)
gsc.kFilter = 0.5;                  % Factor for measurement cut-off frequency (recommended < 0.5)
gsc.mmax = 0.5;                     % 0.5 for sinusoidal PWM; 0.5774 for third harmonic injection
gsc.maxDeltaVdc = 150/gsc.Vdcbase;  % Max voltage ripple on the dc-link [pu]
gsc.maxDeltaP = 360.5e3/gsc.Sbase; 	% Max power to be supplied by dc-link
gsc.maxDeltaT = 1 / (8*grid.fn);	% Max time to supply DeltaP (recommended = 1/8 of a grid cycle) 

[designOk, gsc.filter, gsc.filterpu, gsc.ctrl] = VSCdesignpu(gsc);


%% Energy Storage Devices 

% Primary Control Storage (ES1) Parameters
switch(caseNumber)
    case 1
        es1.Prated = 1;                     % Rated power [W]
    case 2
        es1.Prated = 1.54e6;                % Rated power [W]
    case 3
        es1.Prated = 1;                     % Rated power [W]
    case 4
        es1.Prated = 1.54e6;                % Rated power [W]
    otherwise
        fprintf('Invalid case number.\n');
        return
end


% Secondary Control Storage (ES2) Parameters
switch(caseNumber)
    case 1
        es2.Pfc = 1;                 % Fuel cell rated power [W]
        es2.Pely = 1;                % Electrolizer rated power [W]
    case 2
        es2.Pfc = 4e6;                 % Fuel cell rated power [W]
        es2.Pely = 6e6;                % Electrolizer rated power [W]
    case 3
        es2.Pfc = 1;                 % Fuel cell rated power [W]
        es2.Pely = 1;                % Electrolizer rated power [W]
    case 4
        es2.Pfc = 4e6;                 % Fuel cell rated power [W]
        es2.Pely = 6e6;                % Electrolizer rated power [W]
    otherwise
        fprintf('Invalid case number.\n');
        return
end

%% Energy Storage System Controllers

% PLL
gsc.pll.Kp = 120;       % Proportional gain
gsc.pll.Ki = 50;        % Integral gain    
gsc.pll.Kd = 3000;      % Derivative gain
gsc.pll.Tr = 100;       % Reset time for derivative gain
gsc.pll.wt0 = 0;        % Initial rotor angle

% Primary active power control
ess.P.Kp = 1/grid.rss;              % Permanent droop (proportional gain)
ess.P.Kd = 0;                       % Transient droop (derivative gain)
ess.P.Tr = 0.1;                     % Reset time for transient droop
ess.P.flp = 0.5 * gsc.ctrl.ffilt;   % Low-pass frequency 
ess.P.DB = 0.0025;                  % Deadband


% Reactive power control
ess.Q.Kp = 1/0.10;                  % Permanent droop (proportional gain)
ess.Q.Kd = 0;                       % Transient droop (derivative gain)
ess.Q.Tr = 100;                     % Reset time for transient droop
ess.Q.flp = 0.5 * gsc.ctrl.ffilt;   % Low-pass frequency 
ess.Q.DB = 0.005;                   % Deadband


% DC-link voltage control
ess.Udc.Kp = 1/gsc.maxDeltaVdc;     % Permanent droop (proportional gain)
ess.Udc.Ki = 30;                    % Integral gain
ess.Udc.Kd = 2;                     % Transient droop (derivative gain)
ess.Udc.Tr = 0.1;                   % Reset time for transient droop
ess.Udc.flp = gsc.ctrl.ffilt;       % Low-pass frequency
ess.Udc.DB = 0.005 * gsc.maxDeltaVdc; % Deadband


%% Turbo-generator Parameters

% Synchronous machines
gt1.SM.Sn = 2*44e6;             % Rated power [VA]
gt1.SM.cosphi = 0.8;            % Rated power factor
gt1.SM.Xd = 2.12;               % d-axis steady-state impendance [pu]
gt1.SM.Xdp = 0.299;             % d-axis transient impendance [pu]
gt1.SM.Xdpp = 0.188;            % d-axis subtransient impendance [pu]
gt1.SM.Xq = 0.982;              % q-axis steady-state impendance [pu]
gt1.SM.Xqpp = 0.24;             % q-axis subtransient impendance [pu]
gt1.SM.Xl = 0.131;              % Leakage impendance [pu]
gt1.SM.TdpSC = 0.92;            % d-axis transient time - short-circuit [s]
gt1.SM.TdppSC = 0.022;          % d-axis subtransient time - short-circuit [s]
gt1.SM.TqppSC = 0.0334;         % q-axis subtransient time - short-circuit [s]
gt1.SM.Rs = 0.0242;             % Stator (armature) resistance [pu]
gt1.SM.M = 5.1*88/70;           % Inertia constant [s]
gt1.SM.p = 2;                   % Pairs of poles

% Turbine
gt1.Turb.T = 2.25;              % Equivalent first-order delay [s]


%% Turbo-generator Controllers

% Excitation system
gt1.exc.Tr = 1/(2*grid.fn);     % Input filter time constant [s]
gt1.exc.Ka = 100;               % Proportional gain
gt1.exc.VRmax = 5;              % Maximum output [pu]
gt1.exc.VRmin = gt1.exc.VRmax*cos(deg2rad(150)); % Minimum output [pu]
gt1.exc.Kf = 1e-5;              % Rate feedback (derivative) gain 
gt1.exc.Tf = 0.01;              % Rate feedback (reset) time [s] 
gt1.exc.Tb = 0.01;              % 1st lag time constant [s]
gt1.exc.Tc = gt1.exc.Tb/10;     % 1st lead time constant [s]
gt1.exc.Tb1 = 0;                % 2nd lag time constant [s]
gt1.exc.Tc1 = 0;                % 2nd lead time constant [s]

% Active power control
switch(caseNumber)
    case 1
        gt1.P.Kp = 3e6/(2*gt1.SM.Sn*gt1.SM.cosphi*grid.rss); % Permanent droop (proportional gain)
        gt1.P.DB = 0.005;               % Deadband - Without ESS case
    case 2
        gt1.P.Kp = 24e6/(2*gt1.SM.Sn*gt1.SM.cosphi*grid.rss); % Permanent droop (proportional gain)
        gt1.P.DB = grid.rss;            % Deadband - With ESS case
    case 3
        gt1.P.Kp = 12e6/(2*gt1.SM.Sn*gt1.SM.cosphi*grid.rss); % Permanent droop (proportional gain)
        gt1.P.DB = 0.005;               % Deadband - Without ESS case
    case 4
        gt1.P.Kp = 24e6/(2*gt1.SM.Sn*gt1.SM.cosphi*grid.rss); % Permanent droop (proportional gain)
        gt1.P.DB = grid.rss;            % Deadband - With ESS case
    otherwise
        fprintf('Invalid case number.\n');
        return
end
gt1.P.Kd = 0;                   % Transient droop (derivative gain)
gt1.P.Ki = 0.033;               % Integral gain (secondary control)
gt1.P.Kip = 0.05;               % Propotional gain (secondary control)
gt1.P.Tr = 0.1;                 % Reset time for transient droop
gt1.P.flp = 10;                 % Low-pass frequency 
gt1.P.Ref = 0.4;                % Reference

%% Loads

% Step
ld.step.P = 3e6;                % Step active load [W]
ld.step.cosphi = 0.95;          % Step load power factor
ld.step.st = 0;                 % 1 = load is disconnected; 0 = load is connected


% Fixed
ld.fix.P = 37e6 - ld.step.st*ld.step.P;  % Fixed active load [W]
ld.fix.cosphi = 0.98;           % Fixed load power factor

% Flexible
ld.flex.P = 7.6e6;              % Flexible active load [W]
ld.flex.cosphi = 0.92;          % Flexible load power factor



%% Flexible Load Converter (Flex) parameters

% Base values
flex.Sbase = 11e6;              % Apparent power
flex.Vbase = grid.UB2;          % Line voltage

% L filter
flex.filter.Lac = 0.06 * flex.Vbase^2 / flex.Sbase / (2*pi*grid.fn);
flex.filter.Rac = 0.004 * flex.Vbase^2 / flex.Sbase;

% Active power control
flex.P.Kp = 0.2/grid.rss;       % Permanent droop (proportional gain)
flex.P.Kd = 0;                  % Transient droop (derivative gain)
flex.P.Tr = 0.1;                % Reset time for transient droop
flex.P.flp = 30;                % Low-pass frequency 
flex.P.DB = grid.rss/10;        % Deadband

%% Wind Farm

% Wind turbine parameters
WT.Tlp = 1.2;               % Inertia constant
WT.Rdiam = 126;             % Rotor diameter [m]
WT.Lmm = WT.Rdiam/5;        % Lenght scale [m]
WT.Turb = 6;                % Turbulence intensity [%]
WT.wspeed = 15;             % Wind speed [m/s]

% Power curve - Wind speed [m/s]
WT.pcurve.wind = [0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;25;26;50];
% Power curve - Power [pu]
WT.pcurve.power = [0;0;0;0;0.029;0.0725;0.1304;0.2101;0.3261;0.4638;0.6232;0.7754;0.8913;0.9565;0.9855;1;1;1;0;0];
% Rated power
WT.Prated = 12e6;           % Rated active power [W] 
WT.cosphi = 0.95;           % Rated power factor

% Base values
WT.Sbase = WT.Prated/WT.cosphi;   % Apparent power [VA]
WT.Vbase = grid.UB2;         % Line voltage [V]

% L filter
WT.filter.Lac = 0.10 * WT.Vbase^2 / WT.Sbase / (2*pi*grid.fn);
WT.filter.Rac = 0.004 * WT.Vbase^2 / WT.Sbase;

% Reactive power control
WT.Q.Kp = tan(acos(WT.cosphi))/0.10;          % Permanent droop (proportional gain)
WT.Q.Kd = 0;                  % Transient droop (derivative gain)
WT.Q.Tr = 0.1;                % Reset time for transient droop
WT.Q.flp = 10;               % Low-pass frequency 
WT.Q.DB = 0.005;             % Deadband



%% Simulation Parameters
simu.tTotal = 600;                    % Total simulation time
simu.tStep = 1/(4*gsc.fSwitch);       % Time step (recommended = 1/4 of a switch cycle)  

switch(caseNumber)
    case 1
        simu.tWToff = 1002;                % Time to disconnect Wind Farm
        simu.tLDstep = 2;                  % Time to apply Load Step
    case 2
        simu.tWToff = 1002;                % Time to disconnect Wind Farm
        simu.tLDstep = 2;                  % Time to apply Load Step
    case 3
        simu.tWToff = 2;                   % Time to disconnect Wind Farm
        simu.tLDstep = 1002;               % Time to apply Load Step
    case 4
        simu.tWToff = 2;                   % Time to disconnect Wind Farm
        simu.tLDstep = 1002;               % Time to apply Load Step
    otherwise
        fprintf('Invalid case number.\n');
        return
end