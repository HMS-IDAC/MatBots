classdef imageAnnotationBot < handle    
    properties
        Figure
        Axis
        TransparencyHandle
        Image
        NLabels
        LabelIndex
        LabelMasks
        MouseIsDown
        PenSize
        Dialog
        PenMask
        RadioDraw
        RadioErase
        FolderPath
        ImageName
    end
    
    methods
        
        function bot = imageAnnotationBot(imagePath,nLabels)
            [bot.FolderPath, bot.ImageName] = fileparts(imagePath);
            I = imreadGrayscaleDouble(imagePath);
            
            bot.LabelIndex = 1;
            bot.Image = I;
            J = ones(size(bot.Image));
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
            
            imshow(bot.Image)
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
                                'Position',[100 100 dwidth 5*dborder+6*cheight]);
            labels = cell(1,nLabels);
            for i = 1:nLabels
                labels{i} = sprintf('Class %d',i);
            end
            
            % done button
            uicontrol('Parent',bot.Dialog,'Style','pushbutton','String','Save Labels','Position',[dborder dborder cwidth cheight],'Callback',@bot.buttonDonePushed);
            
            % label popup
            uicontrol('Parent',bot.Dialog,'Style','popupmenu','String',labels,'Position', [dborder 2*dborder+cheight cwidth cheight],'Callback',@bot.popupManage);
            
            % pencil/eraser slider
            bot.PenSize = 5;
            Slider = uicontrol('Parent',bot.Dialog,'Style','slider','Min',1,'Max',10,'Value',bot.PenSize,'Position',[dborder 3*dborder+2*cheight cwidth cheight],'Callback',@bot.sliderManage);
            addlistener(Slider,'Value','PostSet',@bot.continuousSliderManage);
            uicontrol('Parent',bot.Dialog,'Style','text','String','Pencil/Eraser Size','Position',[dborder 3*dborder+3*cheight cwidth cheight],'HorizontalAlignment','left');
            
            bot.PenMask = zeros(size(I));
            bot.PenMask(round(size(I,1)/2),round(size(I,2)/2)) = 1;
            
            % erase/draw
            bot.RadioErase = uicontrol('Parent',bot.Dialog,'Style','radiobutton','Position',[dborder 4*dborder+4*cheight cwidth cheight],'String','Erase','Callback',@bot.radioErase);
            bot.RadioDraw = uicontrol('Parent',bot.Dialog,'Style','radiobutton','Position',[dborder 4*dborder+5*cheight cwidth cheight],'String','Draw','Callback',@bot.radioDraw);
            bot.RadioDraw.Value = 1;
%             uicontrol('Parent',bot.Dialog,'Style','text','String','Mode','Position',[dborder 4*dborder+6*cheight cwidth cheight],'HorizontalAlignment','left');

            uiwait(bot.Dialog)
        end
        
        function radioDraw(bot,src,callbackdata)
            bot.RadioErase.Value = 1-src.Value;
        end
        
        function radioErase(bot,src,callbackdata)
            bot.RadioDraw.Value = 1-src.Value;
        end
        
        function continuousSliderManage(bot,src,callbackdata)
            bot.PenSize = round(callbackdata.AffectedObject.Value);
            set(bot.TransparencyHandle, 'AlphaData', imdilate(bot.PenMask,strel('disk',bot.PenSize,0)));
        end
        
        function sliderManage(bot,src,callbackdata)
            bot.PenSize = round(src.Value);
            set(bot.TransparencyHandle, 'AlphaData', bot.LabelMasks(:,:,bot.LabelIndex));
        end
 
        function popupManage(bot,src,callbackdata)
            bot.LabelIndex = src.Value;
            set(bot.TransparencyHandle, 'AlphaData', bot.LabelMasks(:,:,bot.LabelIndex));
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
                for i = -ps:ps
                    for j = -ps:ps
                        if sqrt(i*i+j*j) < ps
                            if bot.RadioDraw.Value == 1
                                bot.LabelMasks(row+i,col+j,bot.LabelIndex) = 1;
                            elseif bot.RadioErase.Value == 1
                                bot.LabelMasks(row+i,col+j,bot.LabelIndex) = 0;
                            end
                        end
                    end
                end
            end
            set(bot.TransparencyHandle, 'AlphaData', bot.LabelMasks(:,:,bot.LabelIndex));
        end
        
        function mouseDown(bot,src,callbackdata)
            bot.MouseIsDown = true;
        end
        
        function mouseUp(bot,src,callbackdata)
            bot.MouseIsDown = false;
        end
    end
end
