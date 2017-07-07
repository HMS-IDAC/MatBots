classdef pcbStartupDialog < handle
    properties
        Choice
        Dialog
        ResizeFactor
        ResizeFactorText
    end
   
    methods
        function bot = pcbStartupDialog(resizeFactor)
            bot.ResizeFactor = resizeFactor;

            bot.Choice = 0;

            dwidth = 600;
            dborder = 10;
            bwidth = dwidth-2*dborder;
            bheight = 20;

            bot.Dialog = dialog('WindowStyle', 'modal',...
                                'Name', 'NucleiSegmentationBot',...
                                'CloseRequestFcn', @bot.closeDialog,...
                                'Position',[100 100 dwidth 6*dborder+5*bheight]);

            uicontrol('Parent',bot.Dialog,'Style','text','String','Resize factor','Position',[dborder 5*dborder+4*bheight dwidth/5-dborder bheight],'HorizontalAlignment','left');
            uicontrol('Parent',bot.Dialog,'Style','pushbutton','String','(Why?)','Position',[dwidth/5 5*dborder+4*bheight dwidth/5-dborder bheight],'Callback',@bot.buttonWhyPushed);
            uicontrol('Parent',bot.Dialog,'Style','edit','String',sprintf('%.02f',bot.ResizeFactor),'Position',[2*dwidth/5 5*dborder+4*bheight dwidth/5-dborder bheight],'HorizontalAlignment','left','Callback',@bot.setResizeFactor);
            bot.ResizeFactorText = uicontrol('Parent',bot.Dialog,'Style','text','String','(type value and press Enter to set)','Position',[3*dwidth/5 5*dborder+4*bheight 2*dwidth/5 bheight],'HorizontalAlignment','left');
            
            uicontrol('Parent',bot.Dialog,'Style','pushbutton','String','LABEL (i.e. annotate) image(s).','Position',[dborder 4*dborder+3*bheight bwidth bheight],'Callback',@bot.buttonLabelPushed);
            uicontrol('Parent',bot.Dialog,'Style','pushbutton','String','TRAIN model (assumes images have been labeled).','Position',[dborder 3*dborder+2*bheight bwidth bheight],'Callback',@bot.buttonTrainPushed);            
            uicontrol('Parent',bot.Dialog,'Style','pushbutton','String','SETUP POST-PROCESSING using sample image.','Position',[dborder 2*dborder+bheight bwidth bheight],'Callback',@bot.buttonSetupPostProcPushed);            
            uicontrol('Parent',bot.Dialog,'Style','pushbutton','String','SEGMENT folder of images (assumes TRAIN and SETUP done).','Position',[dborder dborder bwidth bheight],'Callback',@bot.buttonClassifyPushed);
            
            uiwait(bot.Dialog)
        end
       
        function setResizeFactor(bot,src,callbackdata)
            s = src.String;
            n = str2double(s);
            if isnan(n) || not(n > 0 && n <= 1)
                uiwait(errordlg('Factor should be a number in (0,1]', 'Oops'))
            else
                bot.ResizeFactor = n;
                bot.ResizeFactorText.String = sprintf('Recorded value: %.02f', n);
            end
        end
        
        function buttonWhyPushed(bot,src,callbackdata)
            uiwait(msgbox('Downsizing the images reduces processing time, often with negligible loss in accuracy. This can also help on machines with low RAM.','Resize Factor','modal'));
        end
        
        function closeDialog(bot,src,callbackdata)
            bot.Choice = 0;
            delete(bot.Dialog);
        end
        
        function buttonClassifyPushed(bot,src,callbackdata)
            bot.Choice = 4;
            delete(bot.Dialog);
        end
        
        function buttonSetupPostProcPushed(bot,src,callbackdata)
            bot.Choice = 3;
            delete(bot.Dialog);
        end
        
        function buttonTrainPushed(bot,src,callbackdata)
            bot.Choice = 2;
            delete(bot.Dialog);
        end
        
        function buttonLabelPushed(bot,src,callbackdata)
            bot.Choice = 1;
            delete(bot.Dialog);
        end
   end
end