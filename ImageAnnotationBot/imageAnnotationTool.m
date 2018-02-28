classdef imageAnnotationTool < handle    
    properties
        Figure
        Axis
        ImageHandle
        TransparencyHandle
        Image
        NLabels
        LabelIndex
        LabelMasks
        MouseIsDown
        PenSize
        PenSizeText
        Dialog
        RadioDraw
        RadioErase
%         FolderPath
%         ImageName
        DidAnnotate
        Slider
        SliderMin
        SliderMax
        LowerThreshold
        UpperThreshold
        LowerThresholdBox
        UpperThresholdBox
        LowerThresholdSlider
        UpperThresholdSlider
    end
    
    methods
        
        function tool = imageAnnotationTool(I,nLabels,varargin)
            tool.DidAnnotate = 0;
            tool.LabelIndex = 1;
            tool.Image = I;
            J = ones(size(tool.Image));
            J = cat(3,zeros(size(I,1),size(I,2),2),J);
            tool.NLabels = nLabels;
            
            tool.Figure = figure(...%'MenuBar','none', ...
                                 'NumberTitle','off', ...
                                 'Name','Image', ...
                                 'CloseRequestFcn',@tool.closeFigure, ...
                                 'WindowButtonMotionFcn', @tool.mouseMove, ...
                                 'WindowButtonDownFcn', @tool.mouseDown, ...
                                 'WindowButtonUpFcn', @tool.mouseUp, ...
                                 'Resize','on');
            tool.Axis = axes('Parent',tool.Figure,'Position',[0 0 1 1]);
            
            tool.ImageHandle = imshow(tool.Image);
            hold on
            tool.TransparencyHandle = imshow(J);
            hold off
            tool.LabelMasks = zeros(size(tool.Image,1),size(tool.Image,2),tool.NLabels);
            tool.LabelIndex = 1;
            set(tool.TransparencyHandle, 'AlphaData', zeros(size(tool.Image)));
            tool.MouseIsDown = false;
            
            dwidth = 300;
            dborder = 10;
            cwidth = dwidth-2*dborder;
            cheight = 20;
            
            tool.Dialog = dialog('WindowStyle', 'normal',...
                                'Name', 'ImageAnnotationBot',...
                                'CloseRequestFcn', @tool.closeDialog,...
                                'Position',[100 100 dwidth 11*dborder+11*cheight]);
            labels = cell(1,nLabels);
            for i = 1:nLabels
                labels{i} = sprintf('Class %d',i);
            end

            uicontrol('Parent',tool.Dialog,'Style','text','String','Lower/Upper Thresholds','Position',[dborder 10*dborder+10*cheight cwidth cheight],'HorizontalAlignment','left');
            
            % lower threshold slider
            tool.LowerThreshold = 0;
            tool.LowerThresholdSlider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0,'Max',1,'Value',tool.LowerThreshold,'Position',[dborder 9*dborder+8*cheight cwidth cheight],'Tag','lts');
            addlistener(tool.LowerThresholdSlider,'Value','PostSet',@tool.continuousSliderManage);
            tool.LowerThresholdBox = uicontrol('Parent',tool.Dialog,'Style','edit','String','0.0000','Position',[dborder 9*dborder+9*cheight 70 cheight],'HorizontalAlignment','left','Tag','ltb','Callback',@tool.changeThreshold);
            
            % upper threshold slider
            tool.UpperThreshold = 1;
            tool.UpperThresholdSlider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0,'Max',1,'Value',tool.UpperThreshold,'Position',[dborder 8*dborder+7*cheight cwidth cheight],'Tag','uts');
            addlistener(tool.UpperThresholdSlider,'Value','PostSet',@tool.continuousSliderManage);
            tool.UpperThresholdBox = uicontrol('Parent',tool.Dialog,'Style','edit','String','1.0000','Position',[dborder+cwidth-70 8*dborder+6*cheight 70 cheight],'HorizontalAlignment','right','Tag','utb','Callback',@tool.changeThreshold);
            
            % erase/draw
            tool.RadioDraw = uicontrol('Parent',tool.Dialog,'Style','radiobutton','Position',[dborder 5*dborder+6*cheight cwidth cheight],'String','Draw','Callback',@tool.radioDraw);
            tool.RadioErase = uicontrol('Parent',tool.Dialog,'Style','radiobutton','Position',[dborder 5*dborder+5*cheight cwidth cheight],'String','Erase','Callback',@tool.radioErase);
            tool.RadioDraw.Value = 1;
            
            % pencil/eraser slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','Pencil/Eraser Size','Position',[dborder 4*dborder+4*cheight cwidth cheight],'HorizontalAlignment','left');
            tool.PenSizeText = uicontrol('Parent',tool.Dialog,'Style','text','String','5','Position',[dborder+cwidth/2-25 3*dborder+3*cheight 50 cheight],'HorizontalAlignment','center');
            uicontrol('Parent',tool.Dialog,'Style','edit','String','10','Position',[dborder+cwidth-50 3*dborder+3*cheight 50 cheight],'HorizontalAlignment','right','Callback',@tool.changeSliderRange,'Tag','sliderMax');
            uicontrol('Parent',tool.Dialog,'Style','edit','String','1','Position',[dborder 3*dborder+3*cheight 50 cheight],'HorizontalAlignment','left','Callback',@tool.changeSliderRange,'Tag','sliderMin');
            tool.PenSize = 5;
            tool.Slider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',1,'Max',10,'Value',tool.PenSize,'Position',[dborder 3*dborder+2*cheight cwidth cheight],'Callback',@tool.sliderManage,'Tag','pss');
            addlistener(tool.Slider,'Value','PostSet',@tool.continuousSliderManage);

            % class popup
            uicontrol('Parent',tool.Dialog,'Style','popupmenu','String',labels,'Position', [dborder 2*dborder+cheight cwidth cheight],'Callback',@tool.popupManage);

            % done button
            if isempty(varargin)
                doneButtonLabel = 'Done';
            else
                doneButtonLabel = varargin;
            end
            uicontrol('Parent',tool.Dialog,'Style','pushbutton','String',doneButtonLabel,'Position',[dborder dborder cwidth cheight],'Callback',@tool.buttonDonePushed);
            
            uiwait(tool.Dialog)
        end
        
        function changeThreshold(tool,src,callbackdata)
            value = str2double(src.String);
            if strcmp(src.Tag,'ltb')
                tool.LowerThreshold = value;
                tool.LowerThresholdSlider.Value = value;
            elseif strcmp(src.Tag,'utb')
                tool.UpperThreshold = value;
                tool.UpperThresholdSlider.Value = value;
            end
            I = tool.Image;
            I(I < tool.LowerThreshold) = tool.LowerThreshold;
            I(I > tool.UpperThreshold) = tool.UpperThreshold;
            I = I-min(I(:));
            I = I/max(I(:));
            tool.ImageHandle.CData = I;
        end
        
        function changeSliderRange(tool,src,callbackdata)
            value = str2double(src.String);
            if strcmp(src.Tag,'sliderMin')
                tool.Slider.Min = value;
                tool.Slider.Value = value;
                tool.PenSize = value;
                tool.PenSizeText.String = sprintf('%d',value);
            elseif strcmp(src.Tag,'sliderMax')
                tool.Slider.Max = value;
                tool.Slider.Value = value;
                tool.PenSize = value;
                tool.PenSizeText.String = sprintf('%d',value);
            end
        end
        
        function radioDraw(tool,src,callbackdata)
            tool.RadioErase.Value = 1-src.Value;
        end
        
        function radioErase(tool,src,callbackdata)
            tool.RadioDraw.Value = 1-src.Value;
        end
        
        function continuousSliderManage(tool,src,callbackdata)
            tag = callbackdata.AffectedObject.Tag;
            if strcmp(tag,'pss')
                tool.PenSize = round(callbackdata.AffectedObject.Value);
                ps = tool.PenSize;
                tool.PenSizeText.String = sprintf('%d',ps);
                [Y,X] = meshgrid(-ps:ps,-ps:ps);
                Mask = sqrt(X.^2+Y.^2) < ps;
                r1 = ceil(tool.Axis.YLim(1));
                r2 = floor(tool.Axis.YLim(2));
                c1 = ceil(tool.Axis.XLim(1));
                c2 = floor(tool.Axis.XLim(2));
                rM = round(mean(tool.Axis.YLim));
                cM = round(mean(tool.Axis.XLim));
                tool.TransparencyHandle.AlphaData(max(1,r1):min(size(tool.Image,1),r2),max(1,c1):min(size(tool.Image,2),c2)) = 0;
                if r1 >= 1 && r2 <= size(tool.Image,1) && c1 >= 1 && c2 <= size(tool.Image,2) ...
                        && rM-ps >= 1 && rM+ps <= size(tool.Image,1) && cM-ps >=1 && cM+ps <= size(tool.Image,2)
                    tool.TransparencyHandle.AlphaData(rM-ps:rM+ps,cM-ps:cM+ps) = Mask;
                end
            else
                value = callbackdata.AffectedObject.Value;
                if strcmp(tag,'uts')
                    tool.UpperThreshold = value;
                    tool.UpperThresholdBox.String = sprintf('%.04f', value);
                elseif strcmp(tag,'lts')
                    tool.LowerThreshold = value;
                    tool.LowerThresholdBox.String = sprintf('%.04f', value);
                end
                I = tool.Image;
                I(I < tool.LowerThreshold) = tool.LowerThreshold;
                I(I > tool.UpperThreshold) = tool.UpperThreshold;
                I = I-min(I(:));
                I = I/max(I(:));
                tool.ImageHandle.CData = I;
            end
        end
        
        function sliderManage(tool,src,callbackdata)
            tool.PenSize = round(src.Value);
            set(tool.TransparencyHandle, 'AlphaData', 0.5*tool.LabelMasks(:,:,tool.LabelIndex));
        end
 
        function popupManage(tool,src,callbackdata)
            tool.LabelIndex = src.Value;
            set(tool.TransparencyHandle, 'AlphaData', 0.5*tool.LabelMasks(:,:,tool.LabelIndex));
        end
        
        function closeDialog(tool,src,callbackdata)
            delete(tool.Dialog);
            delete(tool.Figure);
        end
        
        function buttonDonePushed(tool,src,callbackdata)
            NoOverlap = sum(tool.LabelMasks,3) <= 1;
%             for i = 1:tool.NLabels
%                 imwrite(tool.LabelMasks(:,:,i).*NoOverlap,[tool.FolderPath sprintf('/%s_Class%d.png',tool.ImageName,i)]);
%             end
            tool.LabelMasks = tool.LabelMasks.*repmat(NoOverlap,[1 1 tool.NLabels]);
            tool.DidAnnotate = 1;
            delete(tool.Dialog);
            delete(tool.Figure);
        end
        
        function closeFigure(tool,src,callbackdata)
            delete(tool.Figure);
            delete(tool.Dialog);
        end
        
        function mouseMove(tool,src,callbackdata)
            p = tool.Axis.CurrentPoint;
            col = round(p(1,1));
            row = round(p(1,2));
           
            ps = tool.PenSize;
            if row > ps && row <= size(tool.Image,1)-ps && col > ps && col <= size(tool.Image,2)-ps && tool.MouseIsDown
                [Y,X] = meshgrid(-ps:ps,-ps:ps);
                Curr = tool.LabelMasks(row-ps:row+ps,col-ps:col+ps,tool.LabelIndex);
                Mask = sqrt(X.^2+Y.^2) < ps;
                if tool.RadioDraw.Value == 1
                    tool.LabelMasks(row-ps:row+ps,col-ps:col+ps,tool.LabelIndex) = max(Curr,Mask);
                    tool.TransparencyHandle.AlphaData(row-ps:row+ps,col-ps:col+ps) = 0.5*max(Curr,Mask);
                elseif tool.RadioErase.Value == 1
                    tool.LabelMasks(row-ps:row+ps,col-ps:col+ps,tool.LabelIndex) = min(Curr,1-Mask);
                    tool.TransparencyHandle.AlphaData(row-ps:row+ps,col-ps:col+ps) = min(Curr,0.5*(1-Mask));
                end
            end
        end
        
        function mouseDown(tool,src,callbackdata)
            tool.MouseIsDown = true;
        end
        
        function mouseUp(tool,src,callbackdata)
            tool.MouseIsDown = false;
        end
    end
end
