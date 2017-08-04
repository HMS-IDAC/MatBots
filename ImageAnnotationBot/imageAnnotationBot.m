clear, clc

annotateAnother = true;

while annotateAnother
    [filename, pathname] = uigetfile({'*.tif;*.jpg;*.png','Images (.tif, .jpg, .png)'});
    if filename ~= 0
        answer = inputdlg({'How many labels? (Should be an integer.)'},'',2,{'2'});
        if ~isempty(answer)
            nLabels = str2double(answer{1});
            imageAnnotationTool([pathname filesep filename],nLabels);
        end
    end
    ButtonName = questdlg('Annotate another?','', 'Yes', 'No', 'No');
    if strcmp(ButtonName,'No')
        annotateAnother = false;
    end
end

clear, clc