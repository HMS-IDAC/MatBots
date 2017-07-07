classdef snbStartupDialog < handle
    properties
        Choice
        Dialog
    end
   
    methods
        function app = snbStartupDialog
            app.Choice = 0;

            dwidth = 300;
            dborder = 10;
            bwidth = dwidth-2*dborder;
            bheight = 20;

            app.Dialog = dialog('WindowStyle', 'modal',...
                                'Name', 'SpotsInNucleiBot',...
                                'CloseRequestFcn', @app.closeDialog,...
                                'Position',[100 100 dwidth 3*dborder+2*bheight]);
            
            uicontrol('Parent',app.Dialog,'Style','pushbutton','String','Load or set parameters','Position',[dborder 2*dborder+bheight bwidth bheight],'Callback',@app.buttonSetParametersPushed);
            
            uicontrol('Parent',app.Dialog,'Style','pushbutton','String','Score folder of stacks','Position',[dborder dborder bwidth bheight],'Callback',@app.buttonScoreFolderPushed);
            
            uiwait(app.Dialog)
        end
       
        function closeDialog(app,src,callbackdata)
            app.Choice = 0;
            delete(app.Dialog);
        end
        
        function buttonSetParametersPushed(app,src,callbackdata)
            app.Choice = 1;
            delete(app.Dialog);
        end
        
        function buttonScoreFolderPushed(app,src,callbackdata)
            app.Choice = 2;
            delete(app.Dialog);
        end
   end
end