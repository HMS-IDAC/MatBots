clear, clc

mode = 0;
showedSelect1Message = 0;
showedNavigate2DirMessage = 0;
TST = [];

while 1
    switch mode
        case 0 % home
            MCD = multipleChoiceDialog('TSB',{'Segment Folder','Set Parameters'});
            if MCD.Choice == 0
                break;
            else
                mode = MCD.Choice;
            end
        case 1 % segment folder
            if isempty(TST)
                uiwait(errordlg('Set parameters first.','Error'));
            else
                saveImages = false;
                ButtonName = questdlg({'Would you like to save mask and ID',...
                                       'images to inspect segmentation?',...
                                       '(This can take up a lot of disk space.)'},...
                                       'Save Images', 'Yes', 'No', 'No');
                if strcmp(ButtonName,'Yes')
                    saveImages = true;
                end
                if ~showedNavigate2DirMessage
                    uiwait(msgbox('Next, select folder with images to segment.','Navigate','modal'));
                    showedNavigate2DirMessage = 1;
                end
                dirpath = uigetdir;
                if dirpath ~= 0
                    thresholdSegmentationHeadlessBot(dirpath,TST.ThrModel,saveImages);
                end
            end
            mode = 0;
        case 2 % set parameters
            if ~showedSelect1Message
                uiwait(msgbox('Next, select image to open.','Navigate','modal'));
                showedSelect1Message = 1;
            end
            [filename, pathname] = uigetfile({'*.tif;*.jpg;*.png','Images (.tif, .jpg, .png)'});
            if filename ~= 0
                I = imreadGrayscaleDouble([pathname filesep filename]);
                TST = thresholdSegmentationTool(I);
            end
            mode = 0;
    end
end