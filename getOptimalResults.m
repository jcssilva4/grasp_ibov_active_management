function [optPortfolios,RcumulOpt, CPUTimeOpt, benchRcumul, f] = ...
    getOptimalResults(model, Portfolios, benchPortfolios, period, tetavec)
    T0 = cputime;
    f = [];
    CPUTimeOpt = [];
    optPortfolios = cell(1,period);
    %period = length(tetavec) + 1;
    %lowerperiod = period;
    for t = 1:period
    %for t = lowerperiod:period
        assets = Portfolios{1,t}.initialAssetList;
        auxIdx = 1; %optportIDX
        if(t>1) %if it's not the first period 
            %start optimization
            %clc
            t0 = cputime;
            fprintf('\noptimising %s portfolio',Portfolios{1,t}.date);
            %%%%%%%%%SOLVE WITH GRASP-QUAD%%%%%%%%%%%%%%%%%%%%%%%%%%%  
            if(strcmp('TE',model) ) %Satanna2017
                fprintf('(using TE) ...')
                [Portfolios{1,t}.w, Portfolios{1,t}.finalAssetIdxList, fval] = ...
                    CPLEX_TE(Portfolios{1,t}, tetavec(t-1)); 
                f = [f fval];
            end
            %{
            %new graspquad
            [Portfolios{1,t}.w, ~,...
                Portfolios{1,t}.finalAssetIdxList] = core_graspQ(...
                Portfolios, optPortfolios, t, lambda, 20); 
            %}
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            optimizationCpuTime = cputime - t0;
            CPUTimeOpt = [CPUTimeOpt optimizationCpuTime];
            fprintf('\ndone - optimisation CPU time: %fs\n',optimizationCpuTime);
            %get optPortfolio
            Assets_opt_t = cell(1,length(Portfolios{1,t}.finalAssetIdxList));
            counti = 0;
            for i = 1:length(assets)    
                if(ismember(i,Portfolios{1,t}.finalAssetIdxList))
                    Assets_opt_t{1,auxIdx} = Asset(assets{1,i}.sedol,...
                        assets{1,i}.name, assets{1,i}.sector, assets{1,i}.benchWeight,...
                        assets{1,i}.alphaScore, assets{1,i}.r, Portfolios{1,t}.w(i));
                    auxIdx = auxIdx + 1;
                end
            end
        else %if it is the first period (initial portfolio)
            %Assets_opt_t = [];
            Portfolios{1,t}.w = zeros(1,length(assets));
            Assets_opt_t = cell(1,length(Portfolios{1,t}.initialAssetList));
            for i = 1:length(assets)
                if(Portfolios{1,t}.w(i) >= 0) %check this condition...only wi is required
                    Assets_opt_t{1,auxIdx} = Asset(assets{1,i}.sedol,...
                        assets{1,i}.name, assets{1,i}.sector, assets{1,i}.benchWeight,...
                        assets{1,i}.alphaScore, assets{1,i}.r, 0);
                    auxIdx = auxIdx + 1;
                end
            end
        end
        optPortfolios{1,t} = Portfolio(Assets_opt_t, Portfolios{1,t}.date); %initialize a new portfolio P
    end
    overallCPUTimeOpt = cputime - T0;
    
    %%Calculate performance metrics
    PerformanceMetrics = calcPerformance(optPortfolios, benchPortfolios, period);
    RcumulOpt = PerformanceMetrics{2,6};
    benchRcumul = PerformanceMetrics{3,6};
    %%Analyse Metrics
    clf
    x = 2:period;
    %Compare rbench_t and ropt_t
    hold on
    plot(x, PerformanceMetrics{3,2}, 'b');
    plot(x, PerformanceMetrics{2,2}, 'g');
    legend('rbench_IBOV', 'roptGRASP');
    title('Comparisson between roptGRASP and rbench_IBOV for all periods')
end