classdef pcbModelDialog < handle
    properties
       Dialog
       ModelID
    end
    
    methods
        function app = pcbModelDialog
            scsz = get(0,'ScreenSize'); % scsz = [left bottom width height]
            position = [scsz(3)/2-150 scsz(4)/2-35 300 70];

            app.Dialog = dialog('WindowStyle', 'modal',...
                                'Name', 'Which model?',...
                                'CloseRequestFcn', @app.closeDialog,...
                                'Position',position);

            uicontrol('Parent',app.Dialog,'Style','pushbutton','String','Load model from disk.','Position',[10 10 280 20],'Callback',@app.buttonLoadPushed);
            
            uicontrol('Parent',app.Dialog,'Style','pushbutton','String','Use model in memory.','Position',[10 40 280 20],'Callback',@app.buttonMemoryPushed);

            uiwait(app.Dialog)
        end
        
        function closeDialog(app,src,callbackdata)
            app.ModelID = 0;
            delete(app.Dialog);
        end
        
        function buttonLoadPushed(app,src,callbackdata)
            app.ModelID = 2;
            delete(app.Dialog);
        end
        
        function buttonMemoryPushed(app,src,callbackdata)
            app.ModelID = 1;
            delete(app.Dialog);
        end
    end
end