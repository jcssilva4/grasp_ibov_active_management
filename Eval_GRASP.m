%% Evaluate GRASPs
%% READ DATA, SETUP SIMULATIONS
clear
clc
format long
addpath([pwd '/auxiliar/'])
addpath(['C:/Program Files/IBM/ILOG/CPLEX_Studio128/cplex/matlab/x64_win64/'])
addpath([pwd '/CPLEX/'])
addpath([pwd '/GRASP_QUAD/'])
addpath([pwd '/PerformanceMetrics/']);

% Read data
inputData = Data(); %create a Data object
%inputDataPath = 'C:\Users\GREEFO-CAA\Desktop\IbovespaData\';
inputDataPath = [pwd '\IbovespaData\'];
%read IBOVESPA timeseries.txt
inputData.tsSet = Data.readSP500file([inputDataPath 'timeseries\ibovespaTimeSeries.txt']); clc
%Backtesting setup 
auxIdx = 2; %auxiliar index (get assets name, dates, asset betas)
counter = 1;

Portfolios = cell(1,21); %initialize portfolio variable
nRebalancesPerYear = zeros(1,2); idxRebalance = 1;
initialPeriod = 1;
finalPeriod = 21;
period = initialPeriod;
while(period <= finalPeriod) 
    %get Ibovespa assets
    [initialAssetList, auxIdx, refDate] = Asset.getAll(inputDataPath, inputData.tsSet, auxIdx);
    %read the covMat file associated with refDate
    fprintf ('reading Rmatrix data from %s...', refDate); 
    %getcovMatrix of yyyy-mm-dd
    fid = fopen([inputDataPath 'rmat\rmat_', refDate, '.txt'], 'r');
    raw = textscan(fid, '%s %s %s', 'delimiter', '\t'); 
    fclose(fid);
    fprintf ('ok\n');
    %create a portfolio instance
    P = Portfolio(initialAssetList, refDate); %initialize a new portfolio P
    [P.i_asset, P.j_asset, P.covij] = getIJCovVals(raw, P); %this function is contained in \auxiliar\
    Portfolios{1,period} = P;
    period = period + 1;    
end
%get initial portfolio (0 assets)
P = Portfolio(initialAssetList, 'initial'); %initial portfolio
[P.i_asset, P.j_asset, P.covij] = getIJCovVals(raw, P); %this function is contained in \auxiliar\
Portfolios{1,period} = P;
%flip portfolios vertically (begin from 2016-05-20)
tempP = Portfolios;
for p = 1:period
    Portfolios{1,p} = tempP{1,period-p+1};
end
%%get Bench portfolios
benchPortfolios = cell(1,period-1);
for t = 1:period
    Assets_bench_t = cell(1,length(Portfolios{1,t}.initialAssetList));
    assets = Portfolios{1,t}.initialAssetList;
    auxbIdx = 1; %benchportIDX
    if(t>1) %if it's not the first period 
        for i = 1:length(assets)
            %get benchPortoflio
            if(assets{1,i}.benchWeight > 0)
                Assets_bench_t{1,auxbIdx} = Asset(assets{1,i}.sedol,...
                    assets{1,i}.name, assets{1,i}.sector, assets{1,i}.benchWeight,...
                        assets{1,i}.alphaScore, assets{1,i}.r, assets{1,i}.benchWeight); %check the last arg
                auxbIdx = auxbIdx + 1;
            end
        end
    else %if it is the first period (base portfolio)
        for i = 1:length(assets)
            %get benchPortoflio
            if(assets{1,i}.benchWeight > 0)
                Assets_bench_t{1,auxbIdx} = Asset(assets{1,i}.sedol,...
                     assets{1,i}.name, assets{1,i}.sector, assets{1,i}.benchWeight,...
                        assets{1,i}.alphaScore, assets{1,i}.r, assets{1,i}.benchWeight); %check the last arg
                auxbIdx = auxbIdx + 1;
            end
        end
    end
    benchPortfolios{1,t} = Portfolio(Assets_bench_t, Portfolios{1,t}.date);
end

%% Evaluate TE
clc
teta20 = [0.001 0.001 0.001 0.001 0.001 0.001,...
    0.001 0.001 0.001 0.001 0.001 0.001 0.001 0.001,...
    0.001 0.001 0.001 0.001 0.001 0.001 0.001];

maxEvals = 5;
iters = 80; %GRASP iters
asset_num = 20;
RcumulTE = zeros(1, maxEvals);
gapsTE = zeros(1, maxEvals);
overallCPUTimeTE = zeros(1, maxEvals);
acumTime = 0;
acumSamples = 0;
for eval = 1:maxEvals
    clc
    if(eval < 2)
        fprintf('EVALUATION %d', eval)
    else
        acumTime = acumTime + overallCPUTimeTE(eval-1);
        acumSamples = acumSamples + 1;
        fprintf('EVALUATION %d - mean time per EVAL > %fs', eval, acumTime/acumSamples);
    end
    [RcumulTE(eval), overallCPUTimeTE(eval), benchRcumul, gapsTE(eval)] = ...
        getResults('TE', Portfolios, benchPortfolios,...
        iters, period, GAPS, fvalVECTOR, asset_num, teta20);
end
Results_TE = cell(2,5);
Results_TE{1,1} = 'Mean'; Results_TE{1,2} = 'StdDev'; 
Results_TE{1,3} = 'Min'; Results_TE{1,4} = 'Max';
Results_TE{1,5} = 'MeanCPUTime(s)'; 
Results_TE{1,6} = 'meanGAPS';
Results_TE{2,1} = mean(RcumulTE); Results_TE{2,2} = std(RcumulTE); 
Results_TE{2,3} = min(RcumulTE); Results_TE{2,4} = max(RcumulTE);
Results_TE{2,5} = mean(overallCPUTimeTE);
Results_TE{2,6} = gapsTE;

%% get Roptimal - [Gaivoronski 2005; Sant'Anna 2017] Tracking error
clc

teta20 = [0.004 0.001 0.0008 0.0002 0.0005 0.001,...
    0.001 0.001 0.001 0.001 0.001 0.00095 0.001 0.001,...
    0.001 0.001 0.001 0.002 0.00049 0.0004 0.001];%teta parameter for 20 assets (IBOVESPADATA)

[optPortfolios, RcumulCPLEX, CPUTimeCPLEX, benchRcumul, fval] = ...
    getOptimalResults('TE', Portfolios, benchPortfolios,...
    period, teta20);

fvalVECTOR = fval; %use this to calculate gaps! (use excel)
Results_CPLEX_TE{1,1} = 'meanfval'; 
Results_CPLEX_TE{1,2} = 'MeanCPUTime(s)'; 
Results_CPLEX_TE{2,1} = mean(fval);  
Results_CPLEX_TE{2,2} = mean(CPUTimeCPLEX); 
        %}
 