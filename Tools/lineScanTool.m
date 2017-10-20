classdef lineScanTool < handle    
    properties
        Image
        ImageHandle
        Figure
        Axis
        LineHandle
        
        MouseIsDown
        p0
        p1
        Dialog
        LowerThreshold
        UpperThreshold
    end
    
    methods
        function tool = lineScanTool(I)
% lineScanTool(I)
% Fits a 2-gaussian mixture model to the pixel values under a line drawn in the image.
% Useful to measure the size of diffraction limited spots or filaments.
% Input image I should be in the range [0,1].

            tool.Image = I;
            
            tool.Figure = figure('NumberTitle','off', ...
                                'Name','Line Scan Bot', ...
                                'CloseRequestFcn',@tool.closeFigure, ...
                                'WindowButtonMotionFcn', @tool.mouseMove, ...
                                'WindowButtonDownFcn', @tool.mouseDown, ...
                                'WindowButtonUpFcn', @tool.mouseUp, ...
                                'Resize','on');

            tool.Axis = axes('Parent',tool.Figure,'Position',[0 0 1 1]);
            tool.ImageHandle = imshow(tool.Image);
            hold on
            tool.LineHandle = plot([-2 -1],[-2 -1],'-y'); % placeholder, outside view, just to get LineHandle
            hold off
            tool.MouseIsDown = false;
            
            dwidth = 300;
            dborder = 10;
            cwidth = dwidth-2*dborder;
            cheight = 20;
            
            tool.Dialog = dialog('WindowStyle', 'normal',...
                                'Name', 'Line Scan Bot',...
                                'CloseRequestFcn', @tool.closeDialog,...
                                'Position',[100 100 dwidth 4*dborder+4*cheight],...
                                'Resize','off');
            
            % lower threshold slider
            tool.LowerThreshold = 0;
            LowerThresholdSlider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0,'Max',1,'Value',tool.LowerThreshold,'Position',[dborder 3*dborder+3*cheight cwidth cheight],'Tag','lts');
            addlistener(LowerThresholdSlider,'Value','PostSet',@tool.continuousSliderManage);
            
            % upper threshold slider
            tool.UpperThreshold = 1;
            UpperThresholdSlider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0,'Max',1,'Value',tool.UpperThreshold,'Position',[dborder 2*dborder+2*cheight cwidth cheight],'Tag','uts');
            addlistener(UpperThresholdSlider,'Value','PostSet',@tool.continuousSliderManage);
            
            % quit button
            uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','Done','Position',[dborder dborder cwidth 2*cheight],'Callback',@tool.buttonQuitPushed);
            
            uiwait(msgbox({'Draw a line perpendicular to ridge in image',...
                           'to fit a 2-gaussian mixture model.',...
                           'If fit is proper, take note of smalest sigma.'},'Hint','modal'));
            uiwait(tool.Dialog)
        end
        
        function buttonQuitPushed(tool,src,callbackdata)
            delete(tool.Figure);
            delete(tool.Dialog);
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

                    set(tool.LineHandle,'XData',[col0 col],'YData',[row0 row]);
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

                set(tool.LineHandle,'XData',[],'YData',[]);

                tool.fitGauss1D();
            end
            tool.p0 = [];
            tool.p1 = [];
        end
        
        function fitGauss1D(tool)
            if ~isempty(tool.p0) && ~isempty(tool.p1)
                v = tool.p1-tool.p0;
                d = norm(v);
                if d > 0
                    v = v/d;
                    I = tool.Image;
                    
                    % J = 0.5*I;
                    np = round(d);
                    values = zeros(1,np);
                    for r = 0:np-1
                        row = round(tool.p0(1)+r*v(1));
                        col = round(tool.p0(2)+r*v(2));
                        % J(row,col) = 1;
                        values(r+1) = I(row,col);
                    end
                    figureQSS
                    subplot(1,2,1)
                    imshow(I), hold on
                    plot([tool.p0(2) tool.p1(2)],[tool.p0(1) tool.p1(1)],'-y'), hold off
                    subplot(1,2,2)
                    x = 0:np-1;
                    y = values;
                    plot(x,y,'b'), hold on
                    f = fit(x',y','gauss2');
                    plot(f,x,y), hold off
                    title(sprintf('Gauss2 Fit\nsigmas: %.02f, %.02f', f.c1, f.c2));
                end
            end
        end
    end
end
