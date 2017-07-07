function classifyImagesInFolder(dirPath,rfModel,ppPrmts)

files = dir(dirPath);

nImages = 0;
for i = 1:length(files)
    fName = files(i).name;
    if isempty(strfind(fName,'Nuclei')) && fName(1) ~= '.'
        nImages = nImages+1;
        imagePaths{nImages} = [dirPath filesep fName];
    end
end

h = waitbar(0,'Classifying...');
for i = 1:nImages
    waitbar((i-1)/nImages,h,'Classifying...');
    fprintf('Classifying pixels in image %d of %d\n', i, nImages);
    Mask = mlSegmentationBot.Headless(imagePaths{i},rfModel,ppPrmts);
    [imp,imn,ime] = fileparts(imagePaths{i});
    imwrite(Mask, [imp filesep imn '_Nuclei.png']);
end
close(h)

end