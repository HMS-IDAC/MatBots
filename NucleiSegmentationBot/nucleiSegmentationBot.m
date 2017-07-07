clear, clc

mode = 0;
nLabels = 3; % background, contour, foreground
didAnnotateImages = false;
resizeFactor = 0.25;
MLSB = [];

while 1
    switch mode
        case 0 % startup
            PCBSD = pcbStartupDialog(resizeFactor);
            resizeFactor = PCBSD.ResizeFactor;
            choice = PCBSD.Choice;
            if choice == 0 % quit
                clear PCBSD
                break
            else
                mode = choice;
                clear PCBSD
            end
        case 1 % label
            uiwait(msgbox('Next, navigate to image to label.','Label','modal'));
            [filename, pathname] = uigetfile({'*.tif;*.jpg;*.png','Images (.tif, .jpg, .png)'});
            if filename ~= 0
                IAA = imageAnnotationApp([pathname filename],resizeFactor);
                clear IAA
            end
            mode = 0;
        case 2 % train
            if ~didAnnotateImages
                ButtonName = questdlg({'For training, a folder containing annotated images',...
                                       'must have been created, as instructed in ReadMe.txt.',...
                                       'Navigate to such folder?'}, ...
                                       'Sanity check...', ...
                                       'Ok', 'Cancel', 'Ok');
                if strcmp(ButtonName,'Ok')
                    didAnnotateImages = true;
                end
            end
            if didAnnotateImages
                dirPath = uigetdir;
                if dirPath ~= 0
                    [imageList,labelList,classIndices,originalImageSize] = parseLabelFolder(dirPath,resizeFactor);
                    rfModel = mlrfsTrain(imageList,labelList,classIndices);
                    rfModel.resizeFactor = resizeFactor;
                    rfModel.originalImageSize = originalImageSize;
                    ButtonName = questdlg({'Would you like to save the trained model for',...
                                           'later usage? (It will be saved as rfModel.mat',...
                                           'in the same folder as the labeled images.)'},...
                                           'Save model...', ...
                                           'Yes', 'No', 'Yes');
                    if strcmp(ButtonName,'Yes')
                        modelPath = [dirPath filesep 'rfModel.mat'];
                        fprintf('Saving model at\n%s\n', modelPath);
%                         save(modelPath,'rfModel','-v7.3');
                        save(modelPath,'rfModel');
                        disp('Done.')
                    end
                end
            end
            mode = 0;
        case 3 % setup post-processing
            PCBMD = pcbModelDialog;
            doClassify = false;
            if PCBMD.ModelID == 2
                [filename, pathname] = uigetfile({'*.mat','Model (.mat)'});
                if filename ~= 0
                    disp('Loading model.')
                    load([pathname filename])
                    disp('Done.')
                    doClassify = true;
                end
            elseif PCBMD.ModelID == 1
                if exist('rfModel','var')
                    doClassify = true;
                else
                    uiwait(errordlg('There is no model in memory. Either load a model or train a new one.', 'Oops'));
                end
            end
            clear PCBMD
            if doClassify
                uiwait(msgbox('Next, navigate to sample image to setup post-processing on.','Sample Image','modal'));
                [filename, pathname] = uigetfile({'*.tif;*.jpg;*.png','Images (.tif, .jpg, .png)'});
                if filename ~= 0
                    MLSB = mlSegmentationBot([pathname filename],rfModel);
                end
            end
            mode = 0;
        case 4 % classify
            PCBMD = pcbModelDialog;
            doClassify = false;
            if PCBMD.ModelID == 2
                [filename, pathname] = uigetfile({'*.mat','Model (.mat)'});
                if filename ~= 0
                    disp('Loading model.')
                    load([pathname filename])
                    disp('Done.')
                    doClassify = true;
                end
            elseif PCBMD.ModelID == 1
                if exist('rfModel','var')
                    doClassify = true;
                else
                    uiwait(errordlg('There is no model in memory. Either load a model or train a new one.', 'Oops'));
                end
            end
            clear PCBMD
            if doClassify
                if ~isempty(MLSB) && MLSB.DidSetParameters
                    uiwait(msgbox('Next, navigate to folder containing images to classify.','Classify','modal'));
                    dirPath = uigetdir;
                    if dirPath ~= 0
                        classifyImagesInFolder(dirPath,rfModel,MLSB.PPPrmts);
                    end
                else
                    uiwait(errordlg('No post-processing parameters set.', 'Oops'));
                end
            end
            mode = 0;
    end
end
% clear, clc