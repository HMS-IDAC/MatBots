clear, clc

mode = 0;
showedSelect2Message = 0;
showedNavigate2DirMessage = 0;
STST = [];

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
            if isempty(STST)
                uiwait(errordlg('Set parameters first.','Error'));
            else
                if ~showedNavigate2DirMessage
                    uiwait(msgbox('Next, select folder with images to segment.','Navigate','modal'));
                    showedNavigate2DirMessage = 1;
                end
                dirpath = uigetdir;
                if dirpath ~= 0
                    siameseThresholdSegmentationHeadlessBot(dirpath,STST.ThrModel,true);
                end
            end
            mode = 0;
        case 2 % set parameters
            if ~showedSelect2Message
                uiwait(msgbox('Next, select 2 images to open.','Navigate','modal'));
                showedSelect2Message = 1;
            end
            [filename, pathname] = uigetfile({'*.tif;*.jpg;*.png','Images (.tif, .jpg, .png)'},'MultiSelect','on');
            if isa(filename,'char') 
                uiwait(errordlg('Select 2 images to open.','Error'));
                mode = 2;
            elseif isa(filename,'cell')
                if length(filename) > 2
                    uiwait(errordlg('Select just 2 images to open.','Error'));
                    mode = 2;
                else
                    I1 = imreadGrayscaleDouble([pathname filesep filename{1}]);
                    I2 = imreadGrayscaleDouble([pathname filesep filename{2}]);
                    STST = siameseThresholdSegmentationTool(I1,I2);
                    mode = 0;
                end
            else
                mode = 0;
            end
    end
end