function siameseThresholdSegmentationHeadlessBot(dirPath, thrModel, saveImages)

files = dir(dirPath);

nImages = 0;
for i = 1:length(files)
    fName = files(i).name;
    if isempty(strfind(fName,'_STSB_')) && fName(1) ~= '.'
        nImages = nImages+1;
        imagePaths{nImages} = [dirPath filesep fName];
    end
end

% summaryCell = cell(nImages,2+2*nUsedPSChannels);

h = waitbar(0,'Segmenting...');
for i = 1:nImages
    waitbar((i-1)/nImages,h,'Segmenting...');
    fprintf('Segmenting image %d of %d\n', i, nImages);
    
    I = imreadGrayscaleDouble(imagePaths{i});
    [imp,imn] = fileparts(imagePaths{i});
    
    Mask = siameseThresholdSegmentationTool.Headless(I,thrModel);
    
    if saveImages
        imwrite(Mask,[imp filesep imn '_STSB_Mask.png']);
    end
    
%     summaryCell{i,1} = imn;
%     summaryCell{i,2} = nNuclei;
%     for j = 1:nUsedPSChannels
%         summaryCell{i,2+2*(j-1)+1} = nPointSources(j);
%         summaryCell{i,2+2*(j-1)+2} = nTotalSpotsInNuclei(j);
%     end
end
close(h)

% variableNames = cell(1,2+2*nUsedPSChannels);
% variableNames{1} = 'Stack';
% variableNames{2} = 'N_Nuclei';
% for j = 1:nUsedPSChannels
%     variableNames{2+2*(j-1)+1} = sprintf('Chan%02d_N_Spots', ptSrcChanList(j));
%     variableNames{2+2*(j-1)+2} = sprintf('Chan%02d_N_SpInNuc', ptSrcChanList(j));
% end
% T = cell2table(summaryCell,'VariableNames',variableNames);
% writetable(T,[dirPath filesep '_SNB_Summary.xls']);

end