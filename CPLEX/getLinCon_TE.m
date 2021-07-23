function [A, b] = getLinCon_TE(P, teta)%original
%function [A, lhs, rhs] = getLinCon_Classical(P)%original

    %read files
    inputDataPath = [pwd '\IbovespaData\rmat\'];
    formatQnt = '%s'; %continuous vars
    for i = 1 : length(P.initialAssetList)
        formatQnt = strcat(formatQnt,' %s');
    end
    %get Constraint Matrix
    filepath = [inputDataPath, 'cmat_', P.date, '.txt'];
    fileID = fopen(filepath, 'r');%open timeseries file
    CSet = textscan(fileID, formatQnt, 'delimiter', '\t'); %each column is an asset. Rt = last column 
    fclose(fileID);
    %build Cmat
    Cmat = zeros(length(CSet{1,1}),length(P.initialAssetList)+1);
    for j = 1 : length(P.initialAssetList) + 1
        vec = CSet{1,j};
        samplePeriodSize = length(vec);
        for t = 1:samplePeriodSize
            Cmat(t,j) = str2double(vec{t,1});
        end
    end
    

%original
    %WITH CARD AND FLOOR-CEILING CONSTRAINTS
    nAssets = length(P.initialAssetList);
    nVars = 2*nAssets;
    
    nLinConstr = 2 +(nAssets) + (2*samplePeriodSize);
    %Linear Inequality Constraints (Ax <= b)
    %i -> constraint index, j-> element index(j= 1 = x(1))
    A=zeros(nLinConstr,nVars);
    b=zeros(1,nLinConstr);
    auxc = 1; %auxiliar index that loops through constraints 
    
    %santanna2017 r4: -sum(wi*rit) <= -Rt -lowerTeta
    lowerTeta = -teta;
    for t = 1:samplePeriodSize
        for i = 1:nAssets
            A(auxc, i) = -Cmat(t,i);
        end
        b(auxc) = - lowerTeta - Cmat(t,nAssets+1); %get rhs
        auxc = auxc + 1;
    end
    %santanna2017 r5: sum(wi*rit) <= Rt + upperTeta
    upperTeta = teta;
    for t = 1:samplePeriodSize
        for i = 1:nAssets
            A(auxc, i) = Cmat(t,i);
        end
        b(auxc) = upperTeta + Cmat(t,nAssets+1); %get rhs
        auxc = auxc + 1;
    end
    
    % sigma constraints
    %9.1 20 <= sum(sigmai) <= 40
    for i = nAssets+1:nVars %loop through sigmas 
        A(auxc,i) = -1; %r9.1: -sum(Sigmai) <= -20
        A(auxc + 1,i) = 1; %r9.2: sum(Sigmai) <= 40)
    end
    b(auxc) = -10;
    b(auxc + 1) = 10;
    auxc = auxc + 2; %2 constraints added
    %boundary*Sigma constraints (without asset limit (r9.1)! This is not a NP-HARD problem anymore!)
    %9.3 wi - ub*sigma <= 0
    sub = 1; %w upper bound
    for i = 1:nAssets
        A(auxc,i) = 1;
        A(auxc,i + nAssets) = -sub;
        b(auxc) = 0;
        auxc = auxc + 1;
    end
end