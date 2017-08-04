classdef multipleChoiceDialog < handle
    properties
        Choice
        Dialog
    end
   
    methods
        function dlg = multipleChoiceDialog(dialogTitle,buttonLabels)
            dlg.Choice = 0;

            dwidth = 300;
            dborder = 10;
            bwidth = dwidth-2*dborder;
            bheight = 20;

            nLabels = length(buttonLabels);
            
            dlg.Dialog = dialog('WindowStyle', 'modal',...
                                'Name', dialogTitle,...
                                'CloseRequestFcn', @dlg.closeDialog,...
                                'Position',[100 100 dwidth (nLabels+1)*dborder+nLabels*bheight]);
            
            for i = 1:nLabels
                uicontrol('Parent',dlg.Dialog,'Style','pushbutton','String',buttonLabels{i},'Position',[dborder i*dborder+(i-1)*bheight bwidth bheight],'Callback',@dlg.buttonPushed,'Tag',sprintf('%d',i));
            end
            
            uiwait(dlg.Dialog)
        end
       
        function closeDialog(dlg,src,callbackdata)
            dlg.Choice = 0;
            delete(dlg.Dialog);
        end
        
        function buttonPushed(dlg,src,callbackdata)
            dlg.Choice = str2double(src.Tag);
            delete(dlg.Dialog);
        end
   end
end