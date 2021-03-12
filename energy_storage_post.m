%% Script Parameters
tStart = 0;
tEnd = 340;
saveResults = 1;

switch(caseNumber)
    case 1
        caseDescription = '-step3-noess';
    case 2
        caseDescription = '-step3';
    case 3
        caseDescription = '-step12-noess';
    case 4
        caseDescription = '-step12';
    otherwise
        fprintf('Invalid case number.\n');
        return
end


%% Store results
if saveResults 
    Log.GT = GTLog;
    Log.ESS = ESSLog;
    Log.Flex = FlexLog;
    Log.Sec = SecLog;
    Log.WT = WTLog;

    filename = strcat('energy_storage_results_',datestr(now,'yyyymmdd-hhMM'),caseDescription);
    save(filename, 'es1', 'es2', 'ess', 'flex', 'WT', 'grid', 'gsc', 'gt1', 'ld', 'simu', 'Log'); 
end

%% Prepare datasets for plotting

% Turbo-generator
Plot.w = resample(Log.GT.w,tStart:0.1:tEnd);
Plot.PmGT = resample(Log.GT.Pm,tStart:0.1:tEnd);
Plot.PmGT.Data = Plot.PmGT.Data .* (gt1.SM.Sn/grid.Sb); 
Plot.PeGT = resample(Log.GT.Pm,tStart:0.1:tEnd);
Plot.PeGT.Data = Plot.PeGT.Data .* (gt1.SM.Sn/grid.Sb);

% Energy storage
Plot.IdcES1 = resample(Log.ESS.IdcES1,tStart:0.1:tEnd);
Plot.IdcES2 = resample(Log.ESS.IdcES2,tStart:0.1:tEnd);
Plot.Vdc = resample(Log.ESS.Vdc,tStart:0.1:tEnd);
Plot.PES1 = timeseries(Plot.Vdc.Data .* Plot.IdcES1.Data .* (-es1.Prated/grid.Sb), Plot.Vdc.Time);
Plot.PES2 = timeseries(Plot.Vdc.Data .* Plot.IdcES2.Data .* (-es2.Pely/grid.Sb), Plot.Vdc.Time);

% Flexible load
Plot.PFlex = resample(Log.Flex.Pel,tStart:0.1:tEnd);
Plot.PFlex.Data = Plot.PFlex.Data .* (-flex.Sbase/grid.Sb); 

% Wind farm
Plot.PWT = resample(Log.WT.Pel,tStart:0.1:tEnd);
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


if saveResults
    filename = strcat('results',caseDescription,'.txt');
    writetable(PlotTable,filename,'Delimiter','\t');
end

%% Energy calculations
rtr = 0.05;     % Maximum transient frequency deviation [pu]
rss = 0.02;     % Maximum steady-state frequency deviation [pu]
Tarr = 8; %25;      % Arrest period [s]
Treb = 120; %15;      % Rebound period [s]
Trec = 165; %120;     % Recovery period [s]

% Proposed
EES1arr = 1/12 * Tarr * (2*rtr^2 + 3*rtr);
EES1reb = 1/6 * Treb * (2*rtr^3 + 3*rtr^2 - 2*rss^3 - 3*rss^2) / (rtr - rss);
EES1rec = 1/12 * Trec * (2*rss^2 + 3*rss);

ES1calc = (es1.Prated/rss)/3600 * (EES1arr + EES1reb + EES1rec);

% Simulation
EES1sim = trapz(0.1/3600,Plot.PES1.Data)*grid.Sb;
EES2sim = trapz(0.1/3600,Plot.PES2.Data)*grid.Sb;
