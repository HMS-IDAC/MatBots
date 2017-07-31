classdef imageAnnotationBot < handle    
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
        FolderPath
        ImageName
        Slider
        SliderMin
        SliderMax
        LowerThreshold
        UpperThreshold
    end
    
    methods
        
        function bot = imageAnnotationBot(imagePath,nLabels)
            [bot.FolderPath, bot.ImageName] = fileparts(imagePath);
            I = imreadGrayscaleDouble(imagePath);
            
            bot.LabelIndex = 1;
            bot.Image = I;
            J = ones(size(bot.Image));
            J = cat(3,zeros(size(I,1),size(I,2),2),J);
            bot.NLabels = nLabels;
            
            bot.Figure = figure(...%'MenuBar','none', ...
                                 'NumberTitle','off', ...
                                 'Name','Image', ...
                                 'CloseRequestFcn',@bot.closeFigure, ...
                                 'WindowButtonMotionFcn', @bot.mouseMove, ...
                                 'WindowButtonDownFcn', @bot.mouseDown, ...
                                 'WindowButtonUpFcn', @bot.mouseUp, ...
                                 'Resize','on');
            bot.Axis = axes('Parent',bot.Figure,'Position',[0 0 1 1]);
            
            bot.ImageHandle = imshow(bot.Image);
            hold on
            bot.TransparencyHandle = imshow(J);
            hold off
            bot.LabelMasks = zeros(size(bot.Image,1),size(bot.Image,2),bot.NLabels);
            bot.LabelIndex = 1;
            set(bot.TransparencyHandle, 'AlphaData', zeros(size(bot.Image)));
            bot.MouseIsDown = false;
            
            dwidth = 300;
            dborder = 10;
            cwidth = dwidth-2*dborder;
            cheight = 20;
            
            bot.Dialog = dialog('WindowStyle', 'normal',...
                                'Name', 'ImageAnnotationBot',...
                                'CloseRequestFcn', @bot.closeDialog,...
                                'Position',[100 100 dwidth 10*dborder+10*cheight]);
            labels = cell(1,nLabels);
            for i = 1:nLabels
                labels{i} = sprintf('Class %d',i);
            end

            uicontrol('Parent',bot.Dialog,'Style','text','String','Lower/Upper Thresholds','Position',[dborder 9*dborder+9*cheight cwidth cheight],'HorizontalAlignment','left');
            
            % lower threshold slider
            bot.LowerThreshold = 0;
            lowerThresholdSlider = uicontrol('Parent',bot.Dialog,'Style','slider','Min',0,'Max',1,'Value',bot.LowerThreshold,'Position',[dborder 8*dborder+8*cheight cwidth cheight],'Tag','lts');
            addlistener(lowerThresholdSlider,'Value','PostSet',@bot.continuousSliderManage);
            
            % upper threshold slider
            bot.UpperThreshold = 1;
            upperThresholdSlider = uicontrol('Parent',bot.Dialog,'Style','slider','Min',0,'Max',1,'Value',bot.UpperThreshold,'Position',[dborder 7*dborder+7*cheight cwidth cheight],'Tag','uts');
            addlistener(upperThresholdSlider,'Value','PostSet',@bot.continuousSliderManage);
            
            % erase/draw
            bot.RadioDraw = uicontrol('Parent',bot.Dialog,'Style','radiobutton','Position',[dborder 5*dborder+6*cheight cwidth cheight],'String','Draw','Callback',@bot.radioDraw);
            bot.RadioErase = uicontrol('Parent',bot.Dialog,'Style','radiobutton','Position',[dborder 5*dborder+5*cheight cwidth cheight],'String','Erase','Callback',@bot.radioErase);
            bot.RadioDraw.Value = 1;
            
            % pencil/eraser slider
            uicontrol('Parent',bot.Dialog,'Style','text','String','Pencil/Eraser Size','Position',[dborder 4*dborder+4*cheight cwidth cheight],'HorizontalAlignment','left');
            bot.PenSizeText = uicontrol('Parent',bot.Dialog,'Style','text','String','5','Position',[dborder+cwidth/2-25 3*dborder+3*cheight 50 cheight],'HorizontalAlignment','center');
            uicontrol('Parent',bot.Dialog,'Style','edit','String','10','Position',[dborder+cwidth-50 3*dborder+3*cheight 50 cheight],'HorizontalAlignment','right','Callback',@bot.changeSliderRange,'Tag','sliderMax');
            uicontrol('Parent',bot.Dialog,'Style','edit','String','1','Position',[dborder 3*dborder+3*cheight 50 cheight],'HorizontalAlignment','left','Callback',@bot.changeSliderRange,'Tag','sliderMin');
            bot.PenSize = 5;
            bot.Slider = uicontrol('Parent',bot.Dialog,'Style','slider','Min',1,'Max',10,'Value',bot.PenSize,'Position',[dborder 3*dborder+2*cheight cwidth cheight],'Callback',@bot.sliderManage,'Tag','pss');
            addlistener(bot.Slider,'Value','PostSet',@bot.continuousSliderManage);

            % class popup
            uicontrol('Parent',bot.Dialog,'Style','popupmenu','String',labels,'Position', [dborder 2*dborder+cheight cwidth cheight],'Callback',@bot.popupManage);

            % done button
            uicontrol('Parent',bot.Dialog,'Style','pushbutton','String','Save Labels','Position',[dborder dborder cwidth cheight],'Callback',@bot.buttonDonePushed);
            
            uiwait(bot.Dialog)
        end
        
        function changeSliderRange(bot,src,callbackdata)
            value = str2double(src.String);
            if strcmp(src.Tag,'sliderMin')
                bot.Slider.Min = value;
                bot.Slider.Value = value;
                bot.PenSize = value;
                bot.PenSizeText.String = sprintf('%d',value);
            elseif strcmp(src.Tag,'sliderMax')
                bot.Slider.Max = value;
                bot.Slider.Value = value;
                bot.PenSize = value;
                bot.PenSizeText.String = sprintf('%d',value);
            end
        end
        
        function radioDraw(bot,src,callbackdata)
            bot.RadioErase.Value = 1-src.Value;
        end
        
        function radioErase(bot,src,callbackdata)
            bot.RadioDraw.Value = 1-src.Value;
        end
        
        function continuousSliderManage(bot,src,callbackdata)
            tag = callbackdata.AffectedObject.Tag;
            if strcmp(tag,'pss')
                bot.PenSize = round(callbackdata.AffectedObject.Value);
                ps = bot.PenSize;
                bot.PenSizeText.String = sprintf('%d',ps);
                [Y,X] = meshgrid(-ps:ps,-ps:ps);
                Mask = sqrt(X.^2+Y.^2) < ps;
                r1 = ceil(bot.Axis.YLim(1));
                r2 = floor(bot.Axis.YLim(2));
                c1 = ceil(bot.Axis.XLim(1));
                c2 = floor(bot.Axis.XLim(2));
                rM = round(mean(bot.Axis.YLim));
                cM = round(mean(bot.Axis.XLim));
                bot.TransparencyHandle.AlphaData(max(1,r1):min(size(bot.Image,1),r2),max(1,c1):min(size(bot.Image,2),c2)) = 0;
                if r1 >= 1 && r2 <= size(bot.Image,1) && c1 >= 1 && c2 <= size(bot.Image,2) ...
                        && rM-ps >= 1 && rM+ps <= size(bot.Image,1) && cM-ps >=1 && cM+ps <= size(bot.Image,2)
                    bot.TransparencyHandle.AlphaData(rM-ps:rM+ps,cM-ps:cM+ps) = Mask;
                end
            else
                value = callbackdata.AffectedObject.Value;
                if strcmp(tag,'uts')
                    bot.UpperThreshold = value;
                elseif strcmp(tag,'lts')
                    bot.LowerThreshold = value;
                end
                I = bot.Image;
                I(I < bot.LowerThreshold) = bot.LowerThreshold;
                I(I > bot.UpperThreshold) = bot.UpperThreshold;
                I = I-min(I(:));
                I = I/max(I(:));
                bot.ImageHandle.CData = I;
            end
        end
        
        function sliderManage(bot,src,callbackdata)
            bot.PenSize = round(src.Value);
            set(bot.TransparencyHandle, 'AlphaData', 0.5*bot.LabelMasks(:,:,bot.LabelIndex));
        end
 
        function popupManage(bot,src,callbackdata)
            bot.LabelIndex = src.Value;
            set(bot.TransparencyHandle, 'AlphaData', 0.5*bot.LabelMasks(:,:,bot.LabelIndex));
        end
        
        function closeDialog(bot,src,callbackdata)
            delete(bot.Dialog);
            delete(bot.Figure);
        end
        
        function buttonDonePushed(bot,src,callbackdata)
            NoOverlap = sum(bot.LabelMasks,3) <= 1;
            for i = 1:bot.NLabels
                imwrite(bot.LabelMasks(:,:,i).*NoOverlap,[bot.FolderPath sprintf('/%s_Class%d.png',bot.ImageName,i)]);
            end
            delete(bot.Dialog);
            delete(bot.Figure);
        end
        
        function closeFigure(bot,src,callbackdata)
            delete(bot.Figure);
            delete(bot.Dialog);
        end
        
        function mouseMove(bot,src,callbackdata)
            p = bot.Axis.CurrentPoint;
            col = round(p(1,1));
            row = round(p(1,2));
           
            ps = bot.PenSize;
            if row > ps && row <= size(bot.Image,1)-ps && col > ps && col <= size(bot.Image,2)-ps && bot.MouseIsDown
                [Y,X] = meshgrid(-ps:ps,-ps:ps);
                Curr = bot.LabelMasks(row-ps:row+ps,col-ps:col+ps,bot.LabelIndex);
                Mask = sqrt(X.^2+Y.^2) < ps;
                if bot.RadioDraw.Value == 1
                    bot.LabelMasks(row-ps:row+ps,col-ps:col+ps,bot.LabelIndex) = max(Curr,Mask);
                    bot.TransparencyHandle.AlphaData(row-ps:row+ps,col-ps:col+ps) = 0.5*max(Curr,Mask);
                elseif bot.RadioErase.Value == 1
                    bot.LabelMasks(row-ps:row+ps,col-ps:col+ps,bot.LabelIndex) = min(Curr,1-Mask);
                    bot.TransparencyHandle.AlphaData(row-ps:row+ps,col-ps:col+ps) = min(Curr,0.5*(1-Mask));
                end
            end
        end
        
        function mouseDown(bot,src,callbackdata)
            bot.MouseIsDown = true;
        end
        
        function mouseUp(bot,src,callbackdata)
            bot.MouseIsDown = false;
        end
    end
end
