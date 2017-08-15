clear, clc

annotateAnother = true;

while annotateAnother
    [filename, pathname] = uigetfile({'*.tif','Volumes (.tif)'});
    if filename ~= 0
        answer = inputdlg({'How many labels? (Should be an integer.)'},'',2,{'2'});
        if ~isempty(answer)
            nLabels = str2double(answer{1});
            V = double(volumeRead([pathname filesep filename]));
            V = V-min(V(:)); V = V./max(V(:));
            IAT = volumeAnnotationTool(V,nLabels);
            if IAT.DidAnnotate
                [~,volumeName] = fileparts([pathname filesep filename]);
                for i = 1:IAT.NLabels
                    volumeWrite(IAT.LabelMasks(:,:,:,i),[pathname filesep volumeName sprintf('_Class%d.tif',i)]);
                end
            end
        end
    end
    ButtonName = questdlg('Annotate another?','', 'Yes', 'No', 'No');
    if strcmp(ButtonName,'No')
        annotateAnother = false;
    end
end

clear, clc