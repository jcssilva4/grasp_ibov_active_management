function [w,Sfinal, fval] = CPLEX_TE(P, teta)
    %optimize via cplex class
    %get general parameters
    assets = P.initialAssetList;
    nAssets = length(P.initialAssetList);
    nVars = 2*nAssets; %di, wi and sigma 
    %[di-> 1:nAssets, wi-> nAssets+1:2*nAssets, sigma_i-> 2*nAssets+1:3*nAssets]
    %get objfunction (H, f)
    H = zeros(nVars);  %initialize coeff matrix:
    COV = getCovMat(P);
    for i = 1:nAssets
        for j = 1:nAssets
            H(i,j) = COV(i,j);
        end
    end
    f = zeros(1, nVars); %initialize linear coeff vec: 
    %get fobj part2
    for i=1:nAssets  
        f(i) = -assets{1,i}.alphaScore; 
    end
    f = f';
    %get linear constraints (Aineq, bineq, Aeq, beq)
    %sum of ws = 1
    Aeq = zeros(1, nVars);
    Aeq(1:nAssets) = 1; %sumwi = 1
    beq = 1; %sumwi = 1
    beq = beq'; %avoids: Dimensions of matrices being concatenated are not consistent.
    [A, b] = getLinCon_TE(P, teta);
    b = b';%avoids: Dimensions of matrices being concatenated are not consistent.
    %get boundaries
    lb = zeros(1,nVars); 
    ub = ones(1,length(lb));
    %get BISCN indicator
    ctype = 'C'; %continuous vars
    for i = 1 : nAssets-1
        ctype = strcat(ctype,'C');
    end
    for i = nAssets + 1 : nVars %bin vars
        ctype = strcat(ctype,'B');
    end
    %set options
    options = cplexoptimset('cplex');
    options.emphasis.mip = 2;
    %options.mip.pool.absgap = 0;
    %options.mip.pool.intensity = 4;
    options.optimalitytarget = 3;
    %options.mip.strategy.dive = 3;
    %options.mip.strategy.heuristicfreq = -1;
    %options.mip.strategy.lbheur = 1;
    %options.mip.strategy.nodeselect = 2;
    options.mip.tolerances.absmipgap = 0;
    options.mip.tolerances.mipgap = 0;
    %GAP GLITCH: https://groups.google.com/forum/#!topic/ampl/dcfQozYROVs
    %options.mip.pool.intensity = 4;
    options.display = 'on';
    %options.mip.strategy.search = 1;
    options.timelimit =  20*60; %in secs
    options.clocktype = 2;
    [x,fval,exitflag,output] = cplexmiqp(H, f, A, b, Aeq, beq, ...
        [], [], [], lb, ub, ctype, [], options);
    output
    fprintf('\nfval -> %f',fval) 
    fprintf('\nteta-> %f', teta)
    %{
    %%show results
    fprintf('\n\nfval: %f', fval);
    fprintf('\noutput: '); output
    fprintf('\n\t\tdi\t\t\t\twi\t\t\tsigma')
    for i = 1:nAssets
        fprintf('\n\t%f\t\t%f\t\t%d', x(i), x(i+nAssets), x(i+(2*nAssets)));
    end
    fprintf('\n\nsum(di)\t\tsum(wi)\t\t(number of stocks)');
    fprintf('\n\n%d\t\t%d\t\t%d', sum(x(i:nAssets)), ...
        sum(x(nAssets+1:2*nAssets)),sum(x((2*nAssets)+1:nVars)));
        %}
        
    %%get results
    Sfinal = []; %assets included
    for i = nAssets+1:nVars
        if(x(i)), Sfinal = [Sfinal i-(nAssets)]; end
    end
    w = zeros(1, length(Sfinal));
    for i = 1:nAssets
        if(ismember(i, Sfinal) > 0)
            w(i) = x(i);
        end
    end
end