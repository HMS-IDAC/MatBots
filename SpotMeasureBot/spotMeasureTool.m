classdef spotMeasureTool < handle    
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
        function tool = spotMeasureTool(I)
            % I should be double in range [0,1]
            
            tool.Image = I;
            
            tool.Figure = figure(...%'MenuBar','none', ...
                                 'NumberTitle','off', ...
                                 'Name','Spot Measure Bot', ...
                                 'CloseRequestFcn',@tool.closeFigure, ...
                                 'WindowButtonMotionFcn', @tool.mouseMove, ...
                                 'WindowButtonDownFcn', @tool.mouseDown, ...
                                 'WindowButtonUpFcn', @tool.mouseUp, ...
                                 'Resize','on');
            tool.Axis = axes('Parent',tool.Figure,'Position',[0 0 1 1]);
            tool.ImageHandle = imshow(tool.Image);
            hold on
            tool.BoxHandle = plot([-2 -1],[-2 -1],'-y'); % placeholder, outside view, just to get BoxHandle
            hold off
            tool.MouseIsDown = false;

            
            dwidth = 200;
            dborder = 10;
            cwidth = dwidth-2*dborder;
            cheight = 20;
            
            tool.Dialog = dialog('WindowStyle', 'normal',...
                                'Name', 'Thresholds',...
                                'CloseRequestFcn', @tool.closeDialog,...
                                'Position',[100 100 dwidth 3*dborder+2*cheight]);
            
            % upper threshold slider
            tool.UpperThreshold = 1;
            Slider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0,'Max',1,'Value',tool.UpperThreshold,'Position',[dborder dborder cwidth cheight],'Callback',@tool.sliderManage,'Tag','uts');
            addlistener(Slider,'Value','PostSet',@tool.continuousSliderManage);
                            
            % lower threshold slider
            tool.LowerThreshold = 0;
            Slider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0,'Max',1,'Value',tool.LowerThreshold,'Position',[dborder 2*dborder+cheight cwidth cheight],'Callback',@tool.sliderManage,'Tag','lts');
            addlistener(Slider,'Value','PostSet',@tool.continuousSliderManage);
            
            uiwait(msgbox({'Draw a rectangle around a spot', 'to estimate sigma of fitting gaussian.'},'Hint','modal'));
            
%             uiwait(tool.Dialog)
        end
        
        function sliderManage(tool,src,callbackdata)
%             disp(src.Value)
        end
        
        function continuousSliderManage(tool,src,callbackdata)
            tag = callbackdata.AffectedObject.Tag;
            value = callbackdata.AffectedObject.Value;
            if strcmp(tag,'uts')
                tool.UpperThreshold = value;
            elseif strcmp(tag,'lts')
                tool.LowerThreshold = value;
            end
            I = tool.Image;
            I(I < tool.LowerThreshold) = tool.LowerThreshold;
            I(I > tool.UpperThreshold) = tool.UpperThreshold;
            I = I-min(I(:));
            I = I/max(I(:));
            tool.ImageHandle.CData = I;
        end
        
        function closeDialog(tool,src,callbackdata)
            delete(tool.Figure);
            delete(tool.Dialog);
        end
        
        function closeFigure(tool,src,callbackdata)
            delete(tool.Figure);
            delete(tool.Dialog);
        end
        
        function mouseMove(tool,src,callbackdata)
            if tool.MouseIsDown
                p = tool.Axis.CurrentPoint;
                col = round(p(1,1));
                row = round(p(1,2));

                if row > 0 && row <= size(tool.Image,1) && col > 0 && col <= size(tool.Image,2)
                    row0 = tool.p0(1);
                    col0 = tool.p0(2);

                    rowA = min(row0,row);
                    rowB = max(row0,row);
                    colA = min(col0,col);
                    colB = max(col0,col);

                    set(tool.BoxHandle,'XData',[colA colB colB colA colA],'YData',[rowA rowA rowB rowB rowA]);
                else
                    tool.MouseIsDown = false;
                    tool.p0 = [];
                    tool.p1 = [];
                end
            end
        end
        
        function mouseDown(tool,src,callbackdata)
            p = tool.Axis.CurrentPoint;
            col = round(p(1,1));
            row = round(p(1,2));
            if row > 0 && row <= size(tool.Image,1) && col > 0 && col <= size(tool.Image,2)
                tool.p0 = [row; col];
                tool.MouseIsDown = true;
            end
        end
        
        function mouseUp(tool,src,callbackdata)
            p = tool.Axis.CurrentPoint;
            col = round(p(1,1));
            row = round(p(1,2));
            if row > 0 && row <= size(tool.Image,1) && col > 0 && col <= size(tool.Image,2)
                tool.p1 = [row; col];
                tool.MouseIsDown = false;
                
                set(tool.BoxHandle,'XData',[],'YData',[]);
                
                tool.fitGauss2D();
            end
            tool.p0 = [];
            tool.p1 = [];
        end
        
        function fitGauss2D(tool)
            if ~isempty(tool.p0) && ~isempty(tool.p1)
                pA = tool.p0; pB = tool.p1;
                rowA = min(pA(1),pB(1));
                rowB = max(pA(1),pB(1));
                colA = min(pA(2),pB(2));
                colB = max(pA(2),pB(2));
                BI = tool.Image(rowA:rowB,colA:colB);
                [y,x] = meshgrid(1:size(BI,2),1:size(BI,1));
                [fitresult, zfit, fiterr, zerr, resnorm, rr] = fmgaussfit(x,y,BI);
                evalFit(x,y,BI,zfit,fitresult)
            end
        end
    end
end
