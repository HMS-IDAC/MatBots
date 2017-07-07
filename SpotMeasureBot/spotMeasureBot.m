classdef spotMeasureBot < handle    
    properties
        Figure
        Axis
        Image
        ImageHandle
        BoxHandle
        MouseIsDown
        p0
        p1
        Dialog
        LowerThreshold
        UpperThreshold
    end
    
    methods
        function bot = spotMeasureBot(varargin)
            if nargin == 0
                uiwait(msgbox('Next, open image containing spots.','Load Image','modal'));
                [filename, pathname] = uigetfile({'*.tif;*.jpg;*.png','Images (.tif, .jpg, .png)'});
                if filename ~= 0
                    imagePath = [pathname filename];
                else
                    return
                end
            elseif nargin == 1
                imagePath = varargin{1};
            end
            
            I = imreadGrayscaleDouble(imagePath);
            
%             I = zeros(size(I)).*(I < 0.25)+I.*(I >= 0.25 & I < 0.75)+ones(size(I)).*(I > 0.75);
            
            bot.Image = I;
            
            bot.Figure = figure(...%'MenuBar','none', ...
                                 'NumberTitle','off', ...
                                 'Name','Spot Measure Bot', ...
                                 'CloseRequestFcn',@bot.closeFigure, ...
                                 'WindowButtonMotionFcn', @bot.mouseMove, ...
                                 'WindowButtonDownFcn', @bot.mouseDown, ...
                                 'WindowButtonUpFcn', @bot.mouseUp, ...
                                 'Resize','on');
            bot.Axis = axes('Parent',bot.Figure,'Position',[0 0 1 1]);
            bot.ImageHandle = imshow(bot.Image);
            hold on
            bot.BoxHandle = plot([-2 -1],[-2 -1],'-y'); % placeholder, outside view, just to get BoxHandle
            hold off
            bot.MouseIsDown = false;

            
            dwidth = 200;
            dborder = 10;
            cwidth = dwidth-2*dborder;
            cheight = 20;
            
            bot.Dialog = dialog('WindowStyle', 'normal',...
                                'Name', 'Thresholds',...
                                'CloseRequestFcn', @bot.closeDialog,...
                                'Position',[100 100 dwidth 3*dborder+2*cheight]);
            
            % upper threshold slider
            bot.UpperThreshold = 1;
            Slider = uicontrol('Parent',bot.Dialog,'Style','slider','Min',0,'Max',1,'Value',bot.UpperThreshold,'Position',[dborder dborder cwidth cheight],'Callback',@bot.sliderManage,'Tag','uts');
            addlistener(Slider,'Value','PostSet',@bot.continuousSliderManage);
                            
            % lower threshold slider
            bot.LowerThreshold = 0;
            Slider = uicontrol('Parent',bot.Dialog,'Style','slider','Min',0,'Max',1,'Value',bot.LowerThreshold,'Position',[dborder 2*dborder+cheight cwidth cheight],'Callback',@bot.sliderManage,'Tag','lts');
            addlistener(Slider,'Value','PostSet',@bot.continuousSliderManage);
            
            uiwait(msgbox({'Draw a rectangle around a spot', 'to estimate sigma of fitting gaussian.'},'Hint','modal'));
            
%             uiwait(bot.Dialog)
        end
        
        function sliderManage(bot,src,callbackdata)
%             disp(src.Value)
        end
        
        function continuousSliderManage(bot,src,callbackdata)
            tag = callbackdata.AffectedObject.Tag;
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
        
        function closeDialog(bot,src,callbackdata)
            delete(bot.Figure);
            delete(bot.Dialog);
        end
        
        function closeFigure(bot,src,callbackdata)
            delete(bot.Figure);
            delete(bot.Dialog);
        end
        
        function mouseMove(bot,src,callbackdata)
            if bot.MouseIsDown
                p = bot.Axis.CurrentPoint;
                col = round(p(1,1));
                row = round(p(1,2));

                if row > 0 && row <= size(bot.Image,1) && col > 0 && col <= size(bot.Image,2)
                    row0 = bot.p0(1);
                    col0 = bot.p0(2);

                    rowA = min(row0,row);
                    rowB = max(row0,row);
                    colA = min(col0,col);
                    colB = max(col0,col);

                    set(bot.BoxHandle,'XData',[colA colB colB colA colA],'YData',[rowA rowA rowB rowB rowA]);
                else
                    bot.MouseIsDown = false;
                    bot.p0 = [];
                    bot.p1 = [];
                end
            end
        end
        
        function mouseDown(bot,src,callbackdata)
            p = bot.Axis.CurrentPoint;
            col = round(p(1,1));
            row = round(p(1,2));
            if row > 0 && row <= size(bot.Image,1) && col > 0 && col <= size(bot.Image,2)
                bot.p0 = [row; col];
                bot.MouseIsDown = true;
            end
        end
        
        function mouseUp(bot,src,callbackdata)
            p = bot.Axis.CurrentPoint;
            col = round(p(1,1));
            row = round(p(1,2));
            if row > 0 && row <= size(bot.Image,1) && col > 0 && col <= size(bot.Image,2)
                bot.p1 = [row; col];
                bot.MouseIsDown = false;
                
                set(bot.BoxHandle,'XData',[],'YData',[]);
                
                bot.fitGauss2D();
            end
            bot.p0 = [];
            bot.p1 = [];
        end
        
        function fitGauss2D(bot)
            if ~isempty(bot.p0) && ~isempty(bot.p1)
                pA = bot.p0; pB = bot.p1;
                rowA = min(pA(1),pB(1));
                rowB = max(pA(1),pB(1));
                colA = min(pA(2),pB(2));
                colB = max(pA(2),pB(2));
                BI = bot.Image(rowA:rowB,colA:colB);
                [y,x] = meshgrid(1:size(BI,2),1:size(BI,1));
                [fitresult, zfit, fiterr, zerr, resnorm, rr] = fmgaussfit(x,y,BI);
                evalFit(x,y,BI,zfit,fitresult)
            end
        end
    end
end
