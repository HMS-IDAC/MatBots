classdef stackViewTool < handle    
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
        function tool = stackViewTool(S)
% A tool to view a stack (an image with multiple planes) one plane at a time.
% 
% Includes lower and upper thresholds for quick simple image equalization.
% 
% To run, call stackViewTool(S), where S is a MxNxL stack of type double.
% 
% Not appropriate for stacks where L is too large, because planes are accessed via
% a popup menu, not a slider.
% 
% Example:
% stackViewTool(double(imread('ngc6543a.jpg'))/255);
            
            tool.NPlanes = size(S,3);
            tool.Stack = S;
            tool.PlaneIndex = 1;
            
            tool.Figure = figure(...%'MenuBar','none', ...
                                 'NumberTitle','off', ...
                                 'Name','Plane 1', ...
                                 'CloseRequestFcn',@tool.closeFigure, ...
                                 'Resize','on');
            tool.Axis = axes('Parent',tool.Figure,'Position',[0 0 1 1]);
            
            imshow(tool.Stack(:,:,tool.PlaneIndex))
            
            dwidth = 200;
            dborder = 10;
            cwidth = dwidth-2*dborder;
            cheight = 20;
            
            tool.Dialog = dialog('WindowStyle', 'normal',...
                                'Name', 'StackViewBot',...
                                'CloseRequestFcn', @tool.closeDialog,...
                                'Position',[100 100 dwidth 4*dborder+3*cheight]);
            
            labels = cell(1,tool.NPlanes);
            for i = 1:tool.NPlanes
                labels{i} = sprintf('Plane %d',i);
            end
            uicontrol('Parent',tool.Dialog,'Style','popupmenu','String',labels,'Position', [dborder 3*dborder+2*cheight cwidth cheight],'Callback',@tool.popupManage);

            % lower threshold slider
            tool.LowerThreshold = 0;
            tool.LowerThresholdSlider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0,'Max',1,'Value',tool.LowerThreshold,'Position',[dborder 2+dborder+cheight cwidth cheight],'Callback',@tool.sliderManage,'Tag','lts');
            addlistener(tool.LowerThresholdSlider,'Value','PostSet',@tool.continuousSliderManage);
            
            % upper threshold slider
            tool.UpperThreshold = 1;
            tool.UpperThresholdSlider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0,'Max',1,'Value',tool.UpperThreshold,'Position',[dborder dborder cwidth cheight],'Callback',@tool.sliderManage,'Tag','uts');
            addlistener(tool.UpperThresholdSlider,'Value','PostSet',@tool.continuousSliderManage);
            
%             uiwait(tool.Dialog)
        end
        
        function sliderManage(tool,src,callbackdata)
%             disp(src.Value)
        end
        
        function popupManage(tool,src,callbackdata)
            tool.PlaneIndex = src.Value;
            tool.Axis.Children.CData = tool.Stack(:,:,tool.PlaneIndex);
            tool.Figure.Name = sprintf('Plane %d', tool.PlaneIndex);
            tool.LowerThreshold = 0;
            tool.UpperThreshold = 1;
            tool.LowerThresholdSlider.Value = 0;
            tool.UpperThresholdSlider.Value = 1;
        end
        
        function continuousSliderManage(tool,src,callbackdata)
            tag = callbackdata.AffectedObject.Tag;
            value = callbackdata.AffectedObject.Value;
            if strcmp(tag,'uts')
                tool.UpperThreshold = value;
            elseif strcmp(tag,'lts')
                tool.LowerThreshold = value;
            end
            I = tool.Stack(:,:,tool.PlaneIndex);
            I(I < tool.LowerThreshold) = tool.LowerThreshold;
            I(I > tool.UpperThreshold) = tool.UpperThreshold;
            I = I-min(I(:));
            I = I/max(I(:));
            tool.Axis.Children.CData = I;
        end
        
        function closeDialog(tool,src,callbackdata)
            delete(tool.Figure);
            delete(tool.Dialog);
        end
        
        function closeFigure(tool,src,callbackdata)
            delete(tool.Figure);
            delete(tool.Dialog);
        end
    end
end
