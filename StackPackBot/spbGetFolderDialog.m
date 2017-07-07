classdef spbGetFolderDialog < handle
    properties
       Dialog
       Choice
    end
    
    methods
        function dlg = spbGetFolderDialog(titleString,instructions)
            scsz = get(0,'ScreenSize'); % scsz = [left bottom width height]
            position = [scsz(3)/2-200 scsz(4)/2-35 400 70];

            dlg.Dialog = dialog('WindowStyle', 'modal',...
                                'Name', titleString,...
                                'CloseRequestFcn', @dlg.closeDialog,...
                                'Position',position);

            uicontrol('Parent',dlg.Dialog,'Style','text','String',instructions,'Position', [10 40 380 20],'HorizontalAlignment','center');
                            
            uicontrol('Parent',dlg.Dialog,'Style','pushbutton','String','Abort','Position',[205 10 185 20],'Callback',@dlg.buttonAbortPushed);
            
            uicontrol('Parent',dlg.Dialog,'Style','pushbutton','String','Go','Position',[10 10 185 20],'Callback',@dlg.buttonGoPushed);
            
            uiwait(dlg.Dialog)
        end 
        
        function buttonAbortPushed(dlg,src,callbackdata)
            dlg.Choice = 0;
            delete(dlg.Dialog);
        end
        
        function buttonGoPushed(dlg,src,callbackdata)
            dlg.Choice = 1;
            delete(dlg.Dialog);
        end
        
        function closeDialog(dlg,src,callbackdata)
            dlg.Choice = 0;
            delete(dlg.Dialog);
        end
    end
end