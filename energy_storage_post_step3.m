%% Store results
Log.GT = GTLog;
Log.ESS = ESSLog;
Log.Flex = FlexLog;
Log.Sec = SecLog;
Log.WT = WTLog;

%filename = strcat('energy_storage_results_',datestr(now,'yyyymmdd-hhMM'));
filename = 'energy_storage_results_step3';
save(filename, 'es1', 'es2', 'ess', 'flex', 'WT', 'grid', 'gsc', 'gt1', 'ld', 'simu', 'Log'); 

%% Prepare datasets for plotting
tmax = 300;

% Turbo-generator
Plot.w = resample(Log.GT.w,0:0.1:tmax);
Plot.PmGT = resample(Log.GT.Pm,0:0.1:tmax);
Plot.PmGT.Data = Plot.PmGT.Data .* (gt1.SM.Pn/grid.Sb); 
Plot.PeGT = resample(Log.GT.Pm,0:0.1:tmax);
Plot.PeGT.Data = Plot.PeGT.Data .* (gt1.SM.Pn/grid.Sb);

% Energy storage
Plot.IdcES1 = resample(Log.ESS.IdcES1,0:0.1:tmax);
Plot.IdcES2 = resample(Log.ESS.IdcES2,0:0.1:tmax);
Plot.Vdc = resample(Log.ESS.Vdc,0:0.1:tmax);
Plot.PES1 = timeseries(Plot.Vdc.Data .* Plot.IdcES1.Data .* (-es1.Prated/grid.Sb), Plot.Vdc.Time);
Plot.PES2 = timeseries(Plot.Vdc.Data .* Plot.IdcES2.Data .* (-es2.Pely/grid.Sb), Plot.Vdc.Time);

% Flexible load
Plot.PFlex = resample(Log.Flex.Pel,0:0.1:tmax);
Plot.PFlex.Data = Plot.PFlex.Data .* (-flex.Sbase/grid.Sb); 

% Wind farm
Plot.PWT = resample(Log.WT.Pel,0:0.1:tmax);
Plot.PWT.Data = Plot.PWT.Data .* (-WT.Sbase/grid.Sb); 

% Save data to ascii file for plotting in Latex
PlotTable = table;
PlotTable.Time = Plot.PmGT.Time;
PlotTable.w = Plot.w.Data;
PlotTable.PmGT = Plot.PmGT.Data;
PlotTable.PeGT = Plot.PeGT.Data;
PlotTable.PES1 = Plot.PES1.Data;
PlotTable.PES2 = Plot.PES2.Data;
PlotTable.PFlex = Plot.PFlex.Data;
PlotTable.PWT = Plot.PWT.Data;

writetable(PlotTable,'results-step3','Delimiter','\t');


%% Energy calculations
rtr = 0.05;     % Maximum transient frequency deviation [pu]
rss = 0.02;     % Maximum steady-state frequency deviation [pu]
Tarr = 25;      % Arrest period [s]
Treb = 15;      % Rebound period [s]
Trec = 120;     % Recovery period [s]

% Proposed
EES1arr = 1/12 * Tarr * (2*rtr^2 + 3*rtr);
EES1reb = 1/6 * Treb * (2*rtr^3 + 3*rtr^2 - 2*rss^3 - 3*rss^2) / (rtr - rss);
EES1rec = 1/12 * Trec * (2*rss^2 + 3*rss);

ES1calc = (es1.Prated/rss)/3600 * (EES1arr + EES1reb + EES1rec);
ES1calc = (70e6*1.16)/3600 * (EES1arr + EES1reb + EES1rec);


% Simulation
EES1sim = trapz(0.1/3600,Plot.PES1.Data)*grid.Sb;
EES2sim = trapz(0.1/3600,Plot.PES2.Data)*grid.Sb;
