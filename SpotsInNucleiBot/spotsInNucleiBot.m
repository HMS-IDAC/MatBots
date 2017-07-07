clear, clc

mode = 0;
S = [];
NucleiMask = [];
NucleiDetectionMethod = []; % 'Threshold','MachineLearning'
SpotDetectionMethod = []; % 'LoG', 'AdvancedLoG'
while 1
    switch mode
        case 0 % startup
            SNBSD = snbStartupDialog;
            mode = SNBSD.Choice;
            if mode == 0 % quit
                break
            end
            clear SNBSD
        case 1 % set parameters
            SPD = setParametersDialog;
            switch SPD.Choice
                case 0 % window closed
                    mode = 0;
                case 1 % load parameters
                    % uiwait(msgbox('Next, navigate to parameters file.','Which parameters?','modal'));
                    [filename, pathname] = uigetfile({'*.mat','snbPrmts (.mat)'});
                    if filename ~= 0
                        load([pathname filename]); % loads snbPrmts.mat
                    end
                    mode = 0;
                case 2 % load/view stack
                    reloadS = true;
                    if ~isempty(S) % maybe just show the one loaded
                        ButtonName = questdlg({'There is a stack already in memory...',...
                                               'Would you like to view it, or load a new one?'},...
                                               'View/Load', ...
                                               'View', 'Load New', 'View');
                        if strcmp(ButtonName,'View')
                            reloadS = false;
                        end
                    end
                    if reloadS
                        [filename, pathname] = uigetfile({'*.tif','Stack (.tif)'});
                        if filename ~= 0
                            S = stackRead([pathname filename]);
                            stackViewBot(S);
                        end
                    else
                        stackViewBot(S);
                    end
                    mode = 1;
                case 3 % set nuclei segmentation parameters
                    if isempty(S)
                        uiwait(errordlg('First, load sample stack.', 'Oops'));
                    else
                        NCD = snbNucleiChannelDialog(size(S,3));
                        if ~isempty(NCD.NucleiChannel)
                            ButtonName = questdlg({'Choose segmentation method...'},'Segmentation Type', ...
                                                   'Simple Threshold', 'Machine Learning', 'Simple Threshold');
                            if strcmp(ButtonName,'Simple Threshold')
                                TSB = thresholdSegmentationBot(S(:,:,NCD.NucleiChannel));
                                NucleiMask = TSB.FinalMask;
                                NucleiDetectionMethod = 'Threshold';
                            elseif strcmp(ButtonName,'Machine Learning')
                                uiwait(msgbox('Next, navigate to nuclei segmentation model.','Which model?','modal'));
                                [filename, pathname] = uigetfile({'*.mat','rfModel (.mat)'});
                                if filename ~= 0
                                    load([pathname filename]); % loads rfModel.mat
                                end
                                MLSB = mlSegmentationBot(imresize(S(:,:,NCD.NucleiChannel),rfModel.resizeFactor),rfModel);
                                NucleiMask = imresize(MLSB.FinalMask,size(S(:,:,1)),'nearest');
                                NucleiDetectionMethod = 'MachineLearning';
                            end
                        end
                    end
                    mode = 1;
                case 4 % set spot detection parameters
                        if isempty(S)
                            uiwait(errordlg('First, load sample stack.', 'Oops'));
                        elseif isempty(NucleiMask)
                            uiwait(errordlg('Please setup nuclei segmentation before spot detection.', 'Oops'));
                        else
                            ButtonName = questdlg({'Choose spot detection method...'},'Detection Method', ...
                                                   'LoG', 'Advanced LoG', 'LoG');
                            if strcmp(ButtonName,'LoG')
                                SDB = spotDetectionBot(S,NCD.NucleiChannel,NucleiMask);
                                SpotDetectionMethod = 'LoG';
                            elseif strcmp(ButtonName,'Advanced LoG')
                                ASDB = advSpotDetectionBot(S,NCD.NucleiChannel);
                                SpotDetectionMethod = 'AdvancedLoG';
                            end
                        end
                    mode = 1;
                case 5 % save parameters
                    snbPrmts.NucleiDetectionMethod = NucleiDetectionMethod;
                    snbPrmts.SpotDetectionMethod = SpotDetectionMethod;
                    snbPrmts.NucleiChannel = NCD.NucleiChannel;
                    if strcmp(NucleiDetectionMethod,'Threshold')
                        snbPrmts.ThrModel = TSB.ThrModel;
                    elseif strcmp(NucleiDetectionMethod,'MachineLearning')
                        snbPrmts.RFModel = MLSB.RFModel;
                        snbPrmts.PPPrmts = MLSB.PPPrmts;
                    end
                    if strcmp(SpotDetectionMethod,'LoG')
                        snbPrmts.SDPrmts = SDB.Prmts;
                    elseif strcmp(SpotDetectionMethod,'AdvancedLoG')
                        snbPrmts.SDPrmts = ASDB.Prmts;
                    end
                    
                    [filename, pathname] = uiputfile('snbPrmts.mat', 'Save parameters as...');
                    save([pathname filename],'snbPrmts');
                    
                    mode = 0;
            end
            clear SPD
        case 2 % score folder
            if ~exist('snbPrmts','var')
                uiwait(errordlg('Please load or set parameters first.', 'Oops'));
            else
                saveImages = false;
                ButtonName = questdlg({'Would you like to save nuclei and spot',...
                                       'images to inspect segmentation/detection?',...
                                       '(This can take up a lot of disk space.)'},...
                                       'Save Images', 'Yes', 'No', 'No');
                if strcmp(ButtonName,'Yes')
                    saveImages = true;
                end
                uiwait(msgbox('Next, navigate to folder with stacks to score.','Navigate','modal'));
                dirPath = uigetdir;
                if dirPath ~= 0
                    spotsInNucleiHeadlessBot(dirPath, snbPrmts, saveImages);
                end
            end
            mode = 0;
    end
end