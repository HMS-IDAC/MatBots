function classifyImagesInFolder(dirPath,rfModel)

files = dir(dirPath);

nImages = 0;
for i = 1:length(files)
    fName = files(i).name;
    if isempty(strfind(fName,'Class')) && fName(1) ~= '.'
        nImages = nImages+1;
        imagePaths{nImages} = [dirPath filesep fName];
    end
end

h = waitbar(0,'Classifying...');
for i = 1:nImages
    waitbar((i-1)/nImages,h,'Classifying...');
    fprintf('Classifying pixels in image %d of %d\n', i, nImages);
    I = imread(imagePaths{i});
    if size(I,3) == 2
        I = I(:,:,1);
    elseif size(I,3) == 3
        I = rgb2gray(I);
    end
    I = normalize(double(I));
    [imL,classProbs] = mlrfsPixelClassify(I,rfModel);
    [imp,imn,ime] = fileparts(imagePaths{i});
    for j = 1:rfModel.nLabels
        imwrite(imL == j, [imp filesep imn sprintf('_Class%d.png',rfModel.classIndices(j))]);
    end
end
close(h)

end