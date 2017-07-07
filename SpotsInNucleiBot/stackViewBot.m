classdef stackViewBot < handle    
    properties
        Figure
        Axis
        PlaneIndex
        NPlanes
        Stack
        Dialog
        LowerThreshold
        UpperThreshold
        LowerThresholdSlider
        UpperThresholdSlider
    end
    
    methods
        function bot = stackViewBot(S)
            bot.NPlanes = size(S,3);
            bot.Stack = S;
            bot.PlaneIndex = 1;
            
            bot.Figure = figure(...%'MenuBar','none', ...
                                 'NumberTitle','off', ...
                                 'Name','Plane 1', ...
                                 'CloseRequestFcn',@bot.closeFigure, ...
                                 'Resize','on');
            bot.Axis = axes('Parent',bot.Figure,'Position',[0 0 1 1]);
            
            imshow(bot.Stack(:,:,bot.PlaneIndex))
            
            dwidth = 200;
            dborder = 10;
            cwidth = dwidth-2*dborder;
            cheight = 20;
            
            bot.Dialog = dialog('WindowStyle', 'normal',...
                                'Name', 'StackViewBot',...
                                'CloseRequestFcn', @bot.closeDialog,...
                                'Position',[100 100 dwidth 4*dborder+3*cheight]);
            
            labels = cell(1,bot.NPlanes);
            for i = 1:bot.NPlanes
                labels{i} = sprintf('Plane %d',i);
            end
            uicontrol('Parent',bot.Dialog,'Style','popupmenu','String',labels,'Position', [dborder 3*dborder+2*cheight cwidth cheight],'Callback',@bot.popupManage);

            % lower threshold slider
            bot.LowerThreshold = 0;
            bot.LowerThresholdSlider = uicontrol('Parent',bot.Dialog,'Style','slider','Min',0,'Max',1,'Value',bot.LowerThreshold,'Position',[dborder 2+dborder+cheight cwidth cheight],'Callback',@bot.sliderManage,'Tag','lts');
            addlistener(bot.LowerThresholdSlider,'Value','PostSet',@bot.continuousSliderManage);
            
            % upper threshold slider
            bot.UpperThreshold = 1;
            bot.UpperThresholdSlider = uicontrol('Parent',bot.Dialog,'Style','slider','Min',0,'Max',1,'Value',bot.UpperThreshold,'Position',[dborder dborder cwidth cheight],'Callback',@bot.sliderManage,'Tag','uts');
            addlistener(bot.UpperThresholdSlider,'Value','PostSet',@bot.continuousSliderManage);
            
            uiwait(bot.Dialog)
        end
        
        function sliderManage(bot,src,callbackdata)
%             disp(src.Value)
        end
        
        function popupManage(bot,src,callbackdata)
            bot.PlaneIndex = src.Value;
            bot.Axis.Children.CData = bot.Stack(:,:,bot.PlaneIndex);
            bot.Figure.Name = sprintf('Plane %d', bot.PlaneIndex);
            bot.LowerThreshold = 0;
            bot.UpperThreshold = 1;
            bot.LowerThresholdSlider.Value = 0;
            bot.UpperThresholdSlider.Value = 1;
        end
        
        function continuousSliderManage(bot,src,callbackdata)
            tag = callbackdata.AffectedObject.Tag;
            value = callbackdata.AffectedObject.Value;
            if strcmp(tag,'uts')
                bot.UpperThreshold = value;
            elseif strcmp(tag,'lts')
                bot.LowerThreshold = value;
            end
            I = bot.Stack(:,:,bot.PlaneIndex);
            I(I < bot.LowerThreshold) = bot.LowerThreshold;
            I(I > bot.UpperThreshold) = bot.UpperThreshold;
            I = I-min(I(:));
            I = I/max(I(:));
            bot.Axis.Children.CData = I;
        end
        
        function closeDialog(bot,src,callbackdata)
            delete(bot.Figure);
            delete(bot.Dialog);
        end
        
        function closeFigure(bot,src,callbackdata)
            delete(bot.Figure);
            delete(bot.Dialog);
        end
    end
end
