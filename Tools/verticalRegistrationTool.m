classdef verticalRegistrationTool < handle
    properties
        FigureImages
        AxisImage
        HandleImage
        HandleOverlay
        Image
        Overlay
        Dialog
        Slider
        Tform
    end
    
    methods
        function tool = verticalRegistrationTool(Moving,Fixed,varargin)
            tool.Image{1} = Moving;
            tool.Image{2} = Fixed;
            tool.Tform = affine2d(eye(3,3));
            
            p = inputParser;
            p.addParameter('MaxShift',50);
            p.addParameter('NHLines',7);
            p.addParameter('NVLines',5);
            p.parse(varargin{:});
            p = p.Results;
            maxShift = p.MaxShift;
            nHLines = p.NHLines;
            nVLines = p.NVLines;
            
            ss = get(0,'ScreenSize'); % [left botton width height]
            tool.FigureImages = figure('Position',[ss(3)/4 ss(4)/4 ss(3)/2 ss(4)/2],...
                'NumberTitle','off', 'Name','Vertical Registration Tool', 'CloseRequestFcn',@tool.closeFigure, 'Resize','on');
            
            vPositions = linspace(1,size(tool.Image{1},2),nVLines+2);
            vPositions = vPositions(2:end-1);
            hPositions = linspace(1,size(tool.Image{1},1),nHLines+2);
            hPositions = hPositions(2:end-1);
            
            tool.AxisImage{1} = subplot(1,3,1);
            tool.HandleImage{1} = imshow(tool.Image{1});
            hold on
            for i = 1:length(vPositions)
                plot([vPositions(i) vPositions(i)], [1 size(tool.Image{1},1)],'y')
            end
            for i = 1:length(hPositions)
                plot([1 size(tool.Image{1},2)], [hPositions(i) hPositions(i)],'y')
            end
            hold off
            
            tool.AxisImage{2} = subplot(1,3,2);
            tool.HandleImage{2} = imshow(tool.Image{2});
            hold on
            for i = 1:length(vPositions)
                plot([vPositions(i) vPositions(i)], [1 size(tool.Image{1},1)],'y')
            end
            for i = 1:length(hPositions)
                plot([1 size(tool.Image{1},2)], [hPositions(i) hPositions(i)],'y')
            end
            hold off
            
            tool.AxisImage{3} = subplot(1,3,3);
            I2Red = zeros(size(tool.Image{2},1),size(tool.Image{2},2),3);
            I2Red(:,:,1) = tool.Image{2};
            tool.HandleImage{3} = imshow(I2Red);
            hold on
            tool.Overlay = zeros(size(tool.Image{1},1),size(tool.Image{1},2),3);
            tool.Overlay(:,:,2) = tool.Image{1}; % green
            tool.HandleOverlay = imshow(tool.Overlay);
            tool.HandleOverlay.AlphaData = 0.5*ones(size(tool.Image{1}));
            hold off
            
            dwidth = 200;
            dborder = 10;
            cwidth = dwidth-2*dborder;
            cheight = 20;
            
            tool.Dialog = dialog('WindowStyle', 'normal',...
                                'Name', 'VRT',...
                                'CloseRequestFcn', @tool.closeDialog,...
                                'Position',[100 100 dwidth 3*dborder+3*cheight]);
            
            % segmentation slider
            Slider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',-maxShift,'Max',maxShift,'Value',0,'Position',[dborder 2*dborder+2*cheight cwidth cheight]);
            addlistener(Slider,'Value','PostSet',@tool.continuousSliderManage);
            
            % quit
            uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','Done','Position',[dborder dborder cwidth 2*cheight],'Callback',@tool.buttonDonePushed);
           
            uiwait(tool.Dialog)
        end
        
        function continuousSliderManage(tool,~,callbackdata)
            value = callbackdata.AffectedObject.Value;
            T = eye(3,3);
            T(3,2) = value;
            tool.Tform = affine2d(T);
            I = imwarp(tool.Image{1},tool.Tform,'OutputView',imref2d(size(tool.Image{1})));
            tool.HandleImage{1}.CData = I;
            tool.Overlay(:,:,2) = I;
            tool.HandleOverlay.CData = tool.Overlay;
        end
        
        function buttonDonePushed(tool,~,~)
            delete(tool.FigureImages);
            delete(tool.Dialog);
        end
        
        function closeDialog(tool,~,~)
            delete(tool.FigureImages);
            delete(tool.Dialog);
        end
        
        function closeFigure(tool,~,~)
            delete(tool.FigureImages);
            delete(tool.Dialog);
        end
    end
end
