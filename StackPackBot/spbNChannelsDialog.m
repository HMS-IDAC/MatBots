classdef spbNChannelsDialog < handle
    properties
       Dialog
       Edit
       NChannels
    end
    
    methods
        function dlg = spbNChannelsDialog
            scsz = get(0,'ScreenSize'); % scsz = [left bottom width height]
            position = [scsz(3)/2-200 scsz(4)/2-35 400 70];

            dlg.Dialog = dialog('WindowStyle', 'normal',...
                                'Name', '# Channels',...
                                'CloseRequestFcn', @dlg.closeDialog,...
                                'Position',position);

            dlg.Edit = uicontrol('Parent',dlg.Dialog,'Style','edit','String','2','Position', [205 40 185 20],'HorizontalAlignment','left');
             
            uicontrol('Parent',dlg.Dialog,'Style','text','String','How many channels?','Position', [10 40 185 20],'HorizontalAlignment','left');
                            
            uicontrol('Parent',dlg.Dialog,'Style','pushbutton','String','Abort','Position',[205 10 185 20],'Callback',@dlg.buttonAbortPushed);
            
            uicontrol('Parent',dlg.Dialog,'Style','pushbutton','String','Go','Position',[10 10 185 20],'Callback',@dlg.buttonGoPushed);
            
            uiwait(dlg.Dialog)
        end 
        
        function buttonAbortPushed(dlg,src,callbackdata)
            dlg.NChannels = 0;
            delete(dlg.Dialog);
        end
        
        function buttonGoPushed(dlg,src,callbackdata)
            dlg.NChannels = str2double(dlg.Edit.String);
            delete(dlg.Dialog);
        end
        
        function closeDialog(dlg,src,callbackdata)
            dlg.NChannels = 0;
            delete(dlg.Dialog);
        end
    end
end