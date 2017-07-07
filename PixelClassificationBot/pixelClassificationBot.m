clear, clc

mode = 0;
nLabels = [];
didAnnotateImages = false;

while 1
    switch mode
        case 0 % startup
            PCBSD = pcbStartupDialog;
            choice = PCBSD.Choice;
            if choice == 0 % quit
                clear PCBSD
                break
            else
                mode = choice;
                clear PCBSD
            end
        case 1 % label
            if isempty(nLabels)
                answer = inputdlg({'How many labels? (Should be an integer > 1.)'},'',2,{'2'});
                if ~isempty(answer)
                    nLabels = str2double(answer{1});
                end
            end
            if ~isempty(nLabels) && ~isnan(nLabels) && nLabels > 1
                uiwait(msgbox('Next, navigate to image to label.','Label','modal'));
                [filename, pathname] = uigetfile({'*.tif;*.jpg;*.png','Images (.tif, .jpg, .png)'});
                if filename ~= 0
                    IAA = imageAnnotationBot([pathname filename],nLabels);
                    clear IAA
                end
                mode = 0;
            elseif nLabels <= 1
                nLabels = [];
                uiwait(errordlg('Number of labels should be an integer > 1.','Oops','modal'))
            else
                nLabels = [];
                mode = 0;
            end
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
                    [imageList,labelList,classIndices] = parseLabelFolder(dirPath);
                    rfModel = mlrfsTrain(imageList,labelList,classIndices);
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
        case 3 % classify
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
                uiwait(msgbox('Next, navigate to folder containing images to classify.','Classify','modal'));
                dirPath = uigetdir;
                if dirPath ~= 0
                    classifyImagesInFolder(dirPath,rfModel);
                end
            end
            mode = 0;
    end
end
clear, clc