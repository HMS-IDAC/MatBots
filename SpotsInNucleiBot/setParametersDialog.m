classdef setParametersDialog < handle
    properties
        Choice
        Dialog
    end
   
    methods
        function app = setParametersDialog
            app.Choice = 0;

            dwidth = 300;
            dborder = 10;
            bwidth = dwidth-2*dborder;
            bheight = 20;

            app.Dialog = dialog('WindowStyle', 'modal',...
                                'Name', 'Set Parameters',...
                                'CloseRequestFcn', @app.closeDialog,...
                                'Position',[100 100 dwidth 8*dborder+7*bheight]);

            uicontrol('Parent',app.Dialog,'Style','text','String','Use previously saved parameters...','Position',[dborder 7*dborder+6*bheight bwidth bheight],'HorizontalAlignment','left');
                            
            uicontrol('Parent',app.Dialog,'Style','pushbutton','String','Load parameters from disk','Position',[dborder 6*dborder+5*bheight bwidth bheight],'Callback',@app.buttonLoadParametersPushed);
            
            
            uicontrol('Parent',app.Dialog,'Style','text','String','...or set parameters using sample stack:','Position',[dborder 5*dborder+4*bheight bwidth bheight],'HorizontalAlignment','left');
            
            uicontrol('Parent',app.Dialog,'Style','pushbutton','String','Load/view sample stack','Position',[dborder 4*dborder+3*bheight bwidth bheight],'Callback',@app.buttonLoadSampleStackPushed);
            
            uicontrol('Parent',app.Dialog,'Style','pushbutton','String','Setup nuclei segmentation parameters','Position',[dborder 3*dborder+2*bheight bwidth bheight],'Callback',@app.buttonSetupNucSegParamsPushed);
            
            uicontrol('Parent',app.Dialog,'Style','pushbutton','String','Setup spot detection parameters','Position',[dborder 2*dborder+bheight bwidth bheight],'Callback',@app.buttonSetupSpotDetParamsPushed);
            
            uicontrol('Parent',app.Dialog,'Style','pushbutton','String','Save parameters to disk','Position',[dborder dborder bwidth bheight],'Callback',@app.buttonSaveParametersPushed);
            
            uiwait(app.Dialog)
        end
       
        function closeDialog(app,src,callbackdata)
            app.Choice = 0;
            delete(app.Dialog);
        end
        
        function buttonLoadParametersPushed(app,src,callbackdata)
            app.Choice = 1;
            delete(app.Dialog);
        end
        
        function buttonLoadSampleStackPushed(app,src,callbackdata)
            app.Choice = 2;
            delete(app.Dialog);
        end
        
        function buttonSetupNucSegParamsPushed(app,src,callbackdata)
            app.Choice = 3;
            delete(app.Dialog);
        end
        
        function buttonSetupSpotDetParamsPushed(app,src,callbackdata)
            app.Choice = 4;
            delete(app.Dialog);
        end
        
        function buttonSaveParametersPushed(app,src,callbackdata)
            app.Choice = 5;
            delete(app.Dialog);
        end
   end
end