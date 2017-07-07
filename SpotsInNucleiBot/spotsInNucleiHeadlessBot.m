function spotsInNucleiHeadlessBot(dirPath, snbPrmts, saveImages)

files = dir(dirPath);

nStacks = 0;
for i = 1:length(files)
    fName = files(i).name;
    if isempty(strfind(fName,'_SNB_')) && fName(1) ~= '.'
        nStacks = nStacks+1;
        stackPaths{nStacks} = [dirPath filesep fName];
    end
end

sdPrmts = snbPrmts.SDPrmts;
nUsedPSChannels = sum(sdPrmts(:,2));

summaryCell = cell(nStacks,2+2*nUsedPSChannels);

h = waitbar(0,'Scoring...');
for i = 1:nStacks
    waitbar((i-1)/nStacks,h,'Scoring...');
    fprintf('Scoring stack %d of %d\n', i, nStacks);
    
    S = stackRead(stackPaths{i});
    [imp,imn,ime] = fileparts(stackPaths{i});
    
    fprintf('\tDetecting nuclei from channel %d\n', snbPrmts.NucleiChannel);
    if strcmp(snbPrmts.NucleiDetectionMethod,'Threshold')
        NucleiMask = thresholdSegmentationBot.Headless(S(:,:,snbPrmts.NucleiChannel),snbPrmts.ThrModel);
    elseif strcmp(snbPrmts.NucleiDetectionMethod,'MachineLearning')
        NucleiMask = mlSegmentationBot.Headless(S(:,:,snbPrmts.NucleiChannel),snbPrmts.RFModel,snbPrmts.PPPrmts);
    end
    if saveImages
        imwrite(NucleiMask,[imp filesep imn sprintf('_SNB_Channel%d.png',snbPrmts.NucleiChannel)]);
    end
    pointSources = cell(1,nUsedPSChannels);
    ptSrcChanList = zeros(1,nUsedPSChannels);
    nPointSources = zeros(1,nUsedPSChannels);
    ptSrcChanIndex = 0;
    for j = 1:size(sdPrmts,1)
        if sdPrmts(j,2) == 1
            fprintf('\tDetecting spots from channel %d\n', sdPrmts(j,1));
            if strcmp(snbPrmts.SpotDetectionMethod,'LoG')
                SpotsMask = spotDetectionBot.Headless(S(:,:,sdPrmts(j,1)), NucleiMask, sdPrmts(j,3), sdPrmts(j,4));
            elseif strcmp(snbPrmts.SpotDetectionMethod,'AdvancedLoG')
                SpotsMask = advSpotDetectionBot.Headless(S(:,:,sdPrmts(j,1)), sdPrmts(j,3), sdPrmts(j,4));
            end
            
            [rows,cols] = find(SpotsMask);
            ps.rows = rows;
            ps.cols = cols;
            ptSrcChanIndex = ptSrcChanIndex+1;
            pointSources{ptSrcChanIndex} = ps;
            ptSrcChanList(ptSrcChanIndex) = sdPrmts(j,1);
            nPointSources(ptSrcChanIndex) = length(rows);
        end
    end
    
    [nNuclei,nTotalSpotsInNuclei] = pointSourceScoring(NucleiMask,pointSources,ptSrcChanList,saveImages,imp,imn);
    
    summaryCell{i,1} = imn;
    summaryCell{i,2} = nNuclei;
    for j = 1:nUsedPSChannels
        summaryCell{i,2+2*(j-1)+1} = nPointSources(j);
        summaryCell{i,2+2*(j-1)+2} = nTotalSpotsInNuclei(j);
    end
end
close(h)

variableNames = cell(1,2+2*nUsedPSChannels);
variableNames{1} = 'Stack';
variableNames{2} = 'N_Nuclei';
for j = 1:nUsedPSChannels
    variableNames{2+2*(j-1)+1} = sprintf('Chan%02d_N_Spots', ptSrcChanList(j));
    variableNames{2+2*(j-1)+2} = sprintf('Chan%02d_N_SpInNuc', ptSrcChanList(j));
end

T = cell2table(summaryCell,'VariableNames',variableNames);
writetable(T,[dirPath filesep '_SNB_Summary.xls']);

end