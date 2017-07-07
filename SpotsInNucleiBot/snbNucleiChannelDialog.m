classdef snbNucleiChannelDialog < handle
    properties
       Dialog
       NucleiChannel
    end
    
    methods
        function app = snbNucleiChannelDialog(nChannels)
            scsz = get(0,'ScreenSize'); % scsz = [left bottom width height]
            position = [scsz(3)/2-200 scsz(4)/2-35 400 70];

            app.Dialog = dialog('WindowStyle', 'modal',...
                                'Name', 'Which one is the nuclei channel?',...
                                'CloseRequestFcn', @app.closeDialog,...
                                'Position',position);

            labels = cell(1,nChannels);
            for i = 1:nChannels
                labels{i} = sprintf('Channel %d',i);
            end
            uicontrol('Parent',app.Dialog,'Style','popupmenu','String',labels,'Position', [10 40 380 20],'Callback',@app.popupManage);
            app.NucleiChannel = 1;
                            
            uicontrol('Parent',app.Dialog,'Style','pushbutton','String','Set','Position',[10 10 380 20],'Callback',@app.buttonSetPushed);

            uiwait(app.Dialog)
        end
        
        function popupManage(app,src,callbackdata)
            app.NucleiChannel = src.Value;
        end
        
        function closeDialog(app,src,callbackdata)
            app.NucleiChannel = [];
            delete(app.Dialog);
        end
        
        function buttonSetPushed(app,src,callbackdata)
            delete(app.Dialog);
        end
    end
end