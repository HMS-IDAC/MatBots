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

summaryCell = cell(nImages,9);

h = waitbar(0,'Segmenting...');
for i = 1:nImages
    waitbar((i-1)/nImages,h,'Segmenting...');
    fprintf('Segmenting image %d of %d\n', i, nImages);
    
    I = imreadGrayscaleDouble(imagePaths{i});
    [imp,imn] = fileparts(imagePaths{i});
    
    Mask = siameseThresholdSegmentationTool.Headless(I,thrModel);
    
    s = regionprops(Mask,'Centroid','Area','ConvexArea','Eccentricity','MajorAxisLength','MinorAxisLength','Perimeter','Solidity');
    props = zeros(length(s),7);
    props(:,1) = (1:length(s))';
    props(:,2) = cat(1,s.Area);
    props(:,3) = cat(1,s.ConvexArea);
    props(:,4) = cat(1,s.Eccentricity);
    props(:,5) = cat(1,s.MajorAxisLength);
    props(:,6) = cat(1,s.MinorAxisLength);
    props(:,7) = cat(1,s.Perimeter);
    props(:,8) = cat(1,s.Solidity);
    varNames = {'id','area','convarea','eccent','majaxlen','minaxlen','perim','solid'};
    T = array2table(props,'VariableNames',varNames);
    outFilePath = [imp filesep imn '_STSB_Props.csv'];
    writetable(T,outFilePath);
    
    medians = median(props(:,2:8));
    summaryCell{i,1} = imn;
    summaryCell{i,2} = length(s);
    for j = 3:9
        summaryCell{i,j} = medians(j-2);
    end
    
    if saveImages
        I = 127*uint8(Mask);
        centroids = cat(1,s.Centroid);
        if ~isempty(centroids)
            labels = cell(1,length(centroids));
            for j = 1:length(centroids)
                labels{j} = sprintf('%d',j);
            end
            J = insertText(I,centroids,labels,'TextColor','red','BoxOpacity',0,'FontSize',10);
        else
            J = I;
        end
        imwrite(J,[imp filesep imn '_STSB_Mask.png']);
    end
end
close(h)

variableNames = {'image','n_nuclei','med_area','med_convarea','med_ecc','med_majal','med_minal','med_perim','med_solid'};
T = cell2table(summaryCell,'VariableNames',variableNames);
writetable(T,[dirPath filesep '_STSB_Summary.xls']);

end