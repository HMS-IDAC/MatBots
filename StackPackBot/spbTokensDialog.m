classdef spbTokensDialog < handle
    properties
       Dialog
       Edits
       Tokens
    end
    
    methods
        function dlg = spbTokensDialog(nChannels)
            scsz = get(0,'ScreenSize'); % scsz = [left bottom width height]
            
            nSpaces = nChannels+2;
            space = 10;
            boxHeight = 20;
            
            totalHeight = (nChannels+1)*boxHeight+nSpaces*space;
            
            position = [scsz(3)/2-200 scsz(4)/2-totalHeight/2 400 totalHeight];

            dlg.Dialog = dialog('WindowStyle', 'normal',...
                                'Name', 'Tokens',...
                                'CloseRequestFcn', @dlg.closeDialog,...
                                'Position',position);

            dlg.Tokens = {};
            dlg.Edits = cell(1,nChannels);
            for i = 1:nChannels
                dlg.Edits{i} = uicontrol('Parent',dlg.Dialog,'Style','edit','String',sprintf('token_chan_%d',i),'Position', [10 (1+i)*space+i*boxHeight 400-2*space boxHeight],'HorizontalAlignment','left');
            end
                            
            uicontrol('Parent',dlg.Dialog,'Style','pushbutton','String','Abort','Position',[205 10 185 20],'Callback',@dlg.buttonAbortPushed);
            
            uicontrol('Parent',dlg.Dialog,'Style','pushbutton','String','Go','Position',[10 10 185 20],'Callback',@dlg.buttonGoPushed);
            
            uiwait(dlg.Dialog)
        end 
        
        function buttonAbortPushed(dlg,src,callbackdata)
            delete(dlg.Dialog);
        end
        
        function buttonGoPushed(dlg,src,callbackdata)
            dlg.Tokens = cell(1,length(dlg.Edits));
            for i = 1:length(dlg.Edits)
                dlg.Tokens{i} = dlg.Edits{i}.String;
            end
            delete(dlg.Dialog);
        end
        
        function closeDialog(dlg,src,callbackdata)
            delete(dlg.Dialog);
        end
    end
end