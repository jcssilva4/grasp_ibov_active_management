function [list, eIdx, referenceDate] = getAll(inputDataPath, tsSet, bIdx)
    %bIdx -> initial index position
    %eIdx -> final index position
    listIdx = 1; %assists asset list construction
    auxIdx = bIdx; %assists asset count
    referenceDate = tsSet{1,1}{bIdx};
    %count the number of assets composing S&P500 for that period
    while(strcmp(referenceDate, tsSet{1,1}{auxIdx}))
        auxIdx = auxIdx + 1;
        if(auxIdx>length(tsSet{1,1})) %avoids to exceed matrix dimension
            break;
        end
    end
    fid = fopen([inputDataPath 'rmat\rvec_', referenceDate, '.txt'], 'r');
    rawvec = textscan(fid, '%s %s %s', 'delimiter', '\t'); 
    %fprintf('\nnumber of assets: %d', length(P.initialAssetList))
    vec = rawvec{1,2}; %get rvec value column
    eIdx = auxIdx; %get final index position
    list = cell(1, eIdx - bIdx); %initialize asset list 
    vecidx = 1; %cplexvec idx
    for i = bIdx:(eIdx-1)
        list{1, listIdx} = Asset(tsSet{1,2}{i}, tsSet{1,3}{i},...
            (tsSet{1,4}{i}),str2double(tsSet{1,5}{i}),str2double(vec{vecidx,1}),...
            str2double(tsSet{1,6}{i}),0);
        listIdx = listIdx + 1;
        vecidx = vecidx + 1;
    end
end