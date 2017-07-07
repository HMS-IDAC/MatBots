classdef pcbStartupDialog < handle
    properties
        Choice
        Dialog
    end
   
    methods
        function app = pcbStartupDialog
%             scsz = get(0,'ScreenSize'); % scsz = [left bottom width height]

            app.Choice = 0;

            dwidth = 600;
            dborder = 10;
            bwidth = dwidth-2*dborder;
            bheight = 20;

            app.Dialog = dialog('WindowStyle', 'modal',...
                                'Name', 'PixelClassificationBot',...
                                'CloseRequestFcn', @app.closeDialog,...
                                'Position',[100 100 dwidth 4*dborder+3*bheight]);

            uicontrol('Parent',app.Dialog,'Style','pushbutton','String','CLASSIFY folder of images (assumes model has been trained).','Position',[dborder dborder bwidth bheight],'Callback',@app.buttonClassifyPushed);
            
            uicontrol('Parent',app.Dialog,'Style','pushbutton','String','TRAIN model (assumes images have been labeled).','Position',[dborder 2*dborder+bheight bwidth bheight],'Callback',@app.buttonTrainPushed);
            
            uicontrol('Parent',app.Dialog,'Style','pushbutton','String','LABEL (i.e. annotate) image(s).','Position',[dborder 3*dborder+2*bheight bwidth bheight],'Callback',@app.buttonLabelPushed);
            
            uiwait(app.Dialog)
        end
       
        function closeDialog(app,src,callbackdata)
            app.Choice = 0;
            delete(app.Dialog);
        end
        
        function buttonClassifyPushed(app,src,callbackdata)
            app.Choice = 3;
            delete(app.Dialog);
        end
        
        function buttonTrainPushed(app,src,callbackdata)
            app.Choice = 2;
            delete(app.Dialog);
        end
        
        function buttonLabelPushed(app,src,callbackdata)
            app.Choice = 1;
            delete(app.Dialog);
        end
   end
end