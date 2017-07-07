function rfModel = mlrfsTrain(imageList,labelList,classIndices)

%% set parameters

nLabels = 3; % assumes background, contour, nuclei labels

h = waitbar(0,'Analyzing data...');

nLayers = 1+(length(imageList) > 3);
% number of layers in stacked random forest;
% the algorithm will split the training set in nLayers,
% so that every layer sees a similar distribution of the training set;
% should be an integer >= 1; values > 5 are not recommended

% labels = [1 2 3];
% class labels present in the annotation/label images
% example: if your label images encode label 1, 2, 3, for (respectively) background,
% contour, foreground, you'd set labels = [1 2 3]; you can also
% simply set labels = [1 3] if you only want to detect background and foreground

if length(imageList) < 4
    sigmas = [1 2 4 8 16];
else
    sigmas = [1 2 4 8];
end
% image features are simply derivatives (up to second order) in different scales;
% this parameter specifies such scales; details in imageFeatures.m

offsets = [5 9 13]; %[5 9 13];
% in pixels; for offset features from probability maps (see probMapContextFeatures.m)

% assumes 'foreground' class is class 3
edgeLikFeatOn = true;
probMapELIndex = 3;
% edge likelihoods are computed on the prob map feature of index probMapELIndex;
% example: if labels = [1 3] and you want to compute edge likelihoods
% from label 3, you'd set probMapELIndex = 2, because 3 is at index 2 in labels;
% use-case: this will typically correspond to your 'foreground' class, which
% can be 'nuclei' if you're trying to separate nuclei from background

% assumes round objects are in class 3
% use circularity features on that label map
stats = zeros(length(imageList),4);
for i = 1:length(imageList)
    L = labelList{i} == 3;
    s = regionprops(L,'MajorAxisLength','MinorAxisLength','Eccentricity','Solidity');
    stats(i,1) = mean(cat(1,s.Solidity)); % solidity 
    stats(i,2) = mean(cat(1,s.MinorAxisLength)); % minaxlength
    stats(i,3) = mean(cat(1,s.MajorAxisLength)); % majaxlength
    stats(i,4) = mean(cat(1,s.MajorAxisLength)./cat(1,s.MinorAxisLength)); % ecc
end
if mean(stats(:,1)) > 0.9 && mean(stats(:,4)) < 2.0
    circFeaturesOn = true;
    probMapCFIndex = 3;
    radiiRange = [mean(stats(:,2)) mean(stats(:,3))];
    % range of radii on which to compute circularity features
else
    circFeaturesOn = false;
    probMapCFIndex = 3; % not used, just placeholder
    radiiRange = [13 23]; % not used, just placeholder
end
% circularity features from probability maps (see probMapContextFeatures.m);
% circularity features are computed on the prob map feature of index probMapCFIndex;
% example: if labels = [1 3] and you want to compute circularity features
% from label 3, you'd set probMapCFIndex = 2, because 3 is at index 2 in labels;
% use-case: this will typically correspond to the class containing round
% objects -- which can be 'nuclei' if you're trying to separate nuclei from background;
% it is recommended to use circularity features in such cases,
% since performance tends to improve

pmSigma = 2;
% used in probMapContextFeatures.m for both edge likelihood features and circularity features

nTrees = 20;
% number of decision trees in the random forest ensemble (in each layer)

minLeafSize = 60;
% minimum number of observations per tree leaf (in each layer)

% rfModelFolderPath = 'Model';
% path to folder where model (named rfModel.mat) will be saved

%% compute number of features

nImageFeatures = length(sigmas)*8; % see imageFeatures.m
nProbMapsFeats = length(offsets)*8*nLabels+edgeLikFeatOn+circFeaturesOn*6; % see probMapContextFeatures.m

%% load training set

nImages = length(imageList);
imF = cell(1,nImages);
imL = labelList;
fprintf('Found %d images.\n', nImages);
fprintf('A Random Forest with %d layer(s) will be trained.\n', nLayers);
if edgeLikFeatOn && nLayers > 1
    fprintf('    Model includes edge likelihood features, computed from label %d.\n', classIndices(probMapELIndex));
end
if circFeaturesOn && nLayers > 1
    fprintf('    Model includes circularity features, computed from label %d.\n', classIndices(probMapCFIndex));
    fprintf('        Radii range: [%.0f, %.0f].\n', radiiRange(1), radiiRange(2));
end
fprintf('This might take a while.\n')
for imIndex = 1:nImages
    % fprintf('features %d\n',imIndex);
    I = imageList{imIndex};
    imF{imIndex} = cat(3,imageFeatures(I,sigmas),repmat(zeros(size(I)),[1 1 nLabels+nProbMapsFeats]));
end

%% class balance

waitbar(1/3,h,'Preparing data...');

% max number of pixels per label is 10 % of number of image pixels
maxNPixelsPerLabel = (0.1*(nLayers == 1)+0.01*(nLayers > 1))*size(I,1)*size(I,2);
for imIndex = 1:nImages
    L = imL{imIndex};
%     L1 = label2rgb(L,'winter','k');
    for labelIndex = 1:nLabels
        LLI = L == labelIndex;
        nPixels = sum(sum(LLI));
        rI = rand(size(L)) < maxNPixelsPerLabel/nPixels;
        L(LLI) = 0;
        LLI2 = rI & (LLI > 0);
        L(LLI2) = labelIndex;
    end
    imL{imIndex} = L;
%     L2 = label2rgb(L,'winter','k');
%     imshow([L1 L2])
%     pause
end

%% split training set

nImagesPerLayer = floor(nImages/nLayers);
layerF = cell(nLayers,nImagesPerLayer);
layerL = cell(nLayers,nImagesPerLayer);
for layer = 1:nLayers
    i0 = (layer-1)*nImagesPerLayer;
    for imIndex = 1:nImagesPerLayer
        layerF{layer,imIndex} = imF{i0+imIndex};
        layerL{layer,imIndex} = imL{i0+imIndex};
%         imshow(label2rgb(layerL{layer,imIndex},'jet','k'))
%         title(sprintf('layer %d, image %d', layer, imIndex))
%         pause
    end
end
clear imF
clear imL

%% train layer 1

waitbar(2/3,h,'Training...');

ft = [];
lb = [];
for imIndex = 1:nImagesPerLayer
    F = layerF{1,imIndex};
    L = layerL{1,imIndex};
    [rfFeat,rfLbl] = rffeatandlab(F(:,:,1:nImageFeatures),L);
    ft = [ft; rfFeat];
    lb = [lb; rfLbl];
end
fprintf('Training layer 1...\n');% tic
[treeBag,featImp,oobPredError] = train(ft,lb,nTrees,minLeafSize);
% figureQSS, subplot(1,2,1), plot(featImp,'o'), title('feature importance, layer 1')
% subplot(1,2,2), plot(oobPredError), title('out-of-bag classification error')
% fprintf('training time: %f s\n', toc);
% if exist(rfModelFolderPath,'dir') ~= 7
%     mkdir(rfModelFolderPath);
% end
% save([rfModelFolderPath '/treeBag1.mat'],'treeBag');
% clear treeBag
treeBags = cell(1,nLayers);
treeBags{1} = treeBag;

%% train layers 2...nLayers

for layer = 2:nLayers
    ft = [];
    lb = [];
    for imIndex = 1:nImagesPerLayer
        F = layerF{layer,imIndex};
        L = layerL{layer,imIndex};

        for treeIndex = 1:layer-1
%             load([rfModelFolderPath sprintf('/treeBag%d.mat',treeIndex)]);
            if treeIndex == 1
                [imL,classProbs] = imclassify(F(:,:,1:nImageFeatures),treeBags{treeIndex});
            else
                [imL,classProbs] = imclassify(F,treeBags{treeIndex});
            end
            F(:,:,nImageFeatures+1:nImageFeatures+nLabels) = classProbs;
            F(:,:,nImageFeatures+nLabels+1:end) = probMapContextFeatures(classProbs,offsets,pmSigma,edgeLikFeatOn,probMapELIndex,circFeaturesOn,probMapCFIndex,radiiRange);
        end

        [rfFeat,rfLbl] = rffeatandlab(F,L);
        ft = [ft; rfFeat];
        lb = [lb; rfLbl];
    end

    fprintf('Training layer %d...\n',layer);% tic
    [treeBag,featImp,oobPredError] = train(ft,lb,nTrees,minLeafSize);
%     figureQSS, subplot(1,2,1), plot(featImp,'o'), title(sprintf('feature importance, layer %d',layer))
%     subplot(1,2,2), plot(oobPredError), title('out-of-bag classification error')
%     fprintf('training time: %f s\n', toc);
%     save([rfModelFolderPath sprintf('/treeBag%d.mat',layer)],'treeBag');
%     clear treeBag
    treeBags{layer} = treeBag;
end

%% pack model

waitbar(3/3,h,'Saving model...');

fprintf('Assembling model.\n')
rfModel.nLayers = nLayers;
rfModel.labels = 1:nLabels;
rfModel.nLabels = nLabels;
rfModel.classIndices = classIndices;
rfModel.sigmas = sigmas;
rfModel.offsets = offsets;
rfModel.edgeLikFeatOn = edgeLikFeatOn;
rfModel.probMapELIndex = probMapELIndex;
rfModel.circFeaturesOn = circFeaturesOn;
rfModel.probMapCFIndex = probMapCFIndex;
rfModel.radiiRange = radiiRange;
rfModel.pmSigma = pmSigma;
rfModel.nImageFeatures = nImageFeatures;
rfModel.nProbMapsFeats = nProbMapsFeats;
% treeBags = cell(1,nLayers);
% for i = 1:nLayers
%     load([rfModelFolderPath sprintf('/treeBag%d.mat',i)]);
%     treeBags{i} = treeBag;
%     delete([rfModelFolderPath sprintf('/treeBag%d.mat',i)])
% end
rfModel.treeBags = treeBags;
% disp('saving model')
% tic
% save([rfModelFolderPath '/rfModel.mat'],'rfModel','-v7.3');
% toc
% disp('done training')

close(h)

end