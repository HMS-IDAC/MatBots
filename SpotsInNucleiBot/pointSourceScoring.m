function [nOb,nTotalSpotsInNuclei] = pointSourceScoring(maskIn,ptSrcIn,ptSrcChanList,saveImages,dirPath,stackName)

sOb = regionprops(maskIn,'Centroid','MajorAxisLength','MinorAxisLength','Area'); % statistics of objects (nuclei)
nOb = length(sOb); % number of objects (nuclei)
centroids = cat(1,sOb.Centroid);
radii = mean([cat(1,sOb.MajorAxisLength) cat(1,sOb.MinorAxisLength)],2)/2;
areas = cat(1,sOb.Area);

nChan = length(ptSrcIn);

scores = zeros(nOb,5+nChan); % object ID | center x | center y | radius | area | nChan*counts
scores(:,1) = (1:nOb)';
scores(:,2:3) = round(centroids);
scores(:,4) = round(radii);
scores(:,5) = round(areas);

L = bwlabel(maskIn);
if saveImages
    labels = cell(1,nOb);
    for i = 1:nOb
        labels{i} = sprintf('%d',i);
    end
end
nTotalSpotsInNuclei = zeros(1,nChan);
for iChan = 1:nChan
    ps = ptSrcIn{iChan};
    rows = ps.rows;
    cols = ps.cols;
    
    psCount = zeros(nOb,1);
    for i = 1:length(rows)
        obIdx = L(rows(i),cols(i));
        if obIdx > 0
            psCount(obIdx) = psCount(obIdx)+1;
        end
    end
    
    scores(:,5+iChan) = psCount;
    nTotalSpotsInNuclei(iChan) = sum(psCount);
    
    if saveImages
        I = zeros(size(maskIn));
        if ~isempty(centroids)
            J = insertText(I,centroids,labels,'TextColor','white','BoxOpacity',0,'FontSize', 18);
            J = rgb2gray(J) > 0;
        else
            J = I > 0;
        end
        K = 0.25*maskIn;
        K(J) = 0.5;
        for i = 1:length(rows)
            K(rows(i),cols(i)) = 1;
        end
        
        imwrite(K,[dirPath filesep stackName sprintf('_SNB_Channel%d.png',ptSrcChanList(iChan))]);
    end
end

varNames = cell(1,5+nChan);
varNames{1} = 'obj_id';
varNames{2} = 'cent_x';
varNames{3} = 'cent_y';
varNames{4} = 'radius';
varNames{5} = 'area';
for iChan = 1:nChan
    varNames{5+iChan} = sprintf('nps_ch_%d',ptSrcChanList(iChan));
end
T = array2table(scores,'VariableNames',varNames);
outFilePath = [dirPath filesep stackName '_SNB_Counts.csv'];
writetable(T,outFilePath);

end