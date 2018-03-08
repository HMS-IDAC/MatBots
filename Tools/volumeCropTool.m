classdef volumeCropTool < handle    
    properties
        Figure
        FigureContext
        Axis
        PlaneHandle
        PlaneIndex
        NPlanes
        Volume
        ImageSize
        Dialog
        LowerThreshold
        UpperThreshold
        LowerThresholdSlider
        UpperThresholdSlider
        Slider
        PlaneX
        PlaneY
        PlaneZ
        PlaneXHandle
        PlaneYHandle
        PlaneZHandle
        PlaneXLabel
        PlaneYLabel
        PlaneZLabel
        HLineHandle
        VLineHandle
        PlaneIndexLabel
        RangeSetLeft
        RangeSetRight
        PlaneSlider
        SubVolume
        Ranges
    end
    
    methods
        function tool = volumeCropTool(V)
% volumeCropTool(V)
% A tool to crop a 3D volume
% V should be 'double' and in the range [0,1]
%
% example:
% 
% load mri
% V = double(squeeze(D))/255;
% T = volumeCropTool(V);
% 
% after clicking 'Crop', sub-volume is accessible at T.SubVolume
% cropping ranges are accessible at T.Ranges

            tool.Volume = V;
            for i = 1:3
                tool.NPlanes{i} = size(V,i);
                tool.PlaneIndex{i} = round(tool.NPlanes{i}/2);
            end
            
            tool.LowerThreshold = 0;
            tool.UpperThreshold = 1;
                             
            % y
            tool.Figure{1} = figure('Name','Plane Y','NumberTitle','off','CloseRequestFcn',@tool.closeTool);
            tool.Axis{1} = axes('Parent',tool.Figure{1},'Position',[0 0 1 1]); % subplot(1,3,2);
            I = tool.Volume(tool.PlaneIndex{1},:,:);
            I = reshape(I,[tool.NPlanes{2} tool.NPlanes{3}]);
            tool.PlaneHandle{1} = imshow(tool.applyThresholds(I)); hold on;
            tool.HLineHandle{1} = plot([1 tool.NPlanes{3}],[tool.PlaneIndex{2} tool.PlaneIndex{2}],'r');
            tool.VLineHandle{1} = plot([tool.PlaneIndex{3} tool.PlaneIndex{3}],[1 tool.NPlanes{2}],'b');  hold off;
            tool.ImageSize{1} = size(I);
            tool.PlaneY = [1               tool.PlaneIndex{1} 1              ;...
                           tool.NPlanes{2} tool.PlaneIndex{1} 1              ;...
                           tool.NPlanes{2} tool.PlaneIndex{1} tool.NPlanes{3};...
                           1               tool.PlaneIndex{1} tool.NPlanes{3}];
               
            % x
            tool.Figure{2} = figure('Name','Plane X','NumberTitle','off','CloseRequestFcn',@tool.closeTool,...
                'Position',[tool.Figure{1}.Position(1)+30 tool.Figure{1}.Position(2)-30 tool.Figure{1}.Position(3) tool.Figure{1}.Position(4)]);
            tool.Axis{2} = axes('Parent',tool.Figure{2},'Position',[0 0 1 1]); 
            I = tool.Volume(:,tool.PlaneIndex{2},:);
            I = reshape(I,[tool.NPlanes{1} tool.NPlanes{3}]);
            tool.PlaneHandle{2} = imshow(tool.applyThresholds(I)); hold on;
            tool.HLineHandle{2} = plot([1 tool.NPlanes{3}],[tool.PlaneIndex{1} tool.PlaneIndex{1}],'g');
            tool.VLineHandle{2} = plot([tool.PlaneIndex{3} tool.PlaneIndex{3}],[1 tool.NPlanes{1}],'b');  hold off;
            tool.ImageSize{2} = size(I);
            tool.PlaneX = [tool.PlaneIndex{2} 1               1              ;...
                           tool.PlaneIndex{2} tool.NPlanes{1} 1              ;...
                           tool.PlaneIndex{2} tool.NPlanes{1} tool.NPlanes{3};...
                           tool.PlaneIndex{2} 1               tool.NPlanes{3}];
               
            % z
            tool.Figure{3} = figure('Name','Plane Z','NumberTitle','off','CloseRequestFcn',@tool.closeTool,...
                'Position',[tool.Figure{2}.Position(1)+30 tool.Figure{2}.Position(2)-30 tool.Figure{2}.Position(3) tool.Figure{2}.Position(4)]);
            tool.Axis{3} = axes('Parent',tool.Figure{3},'Position',[0 0 1 1]); % subplot(1,3,3);
            I = tool.Volume(:,:,tool.PlaneIndex{3});
            tool.PlaneHandle{3} = imshow(tool.applyThresholds(I)); hold on;
            tool.HLineHandle{3} = plot([1 tool.NPlanes{2}],[tool.PlaneIndex{1} tool.PlaneIndex{1}],'g');
            tool.VLineHandle{3} = plot([tool.PlaneIndex{2} tool.PlaneIndex{2}],[1 tool.NPlanes{1}],'r');  hold off;
            tool.ImageSize{3} = size(I);
            tool.PlaneZ = [1               1               tool.PlaneIndex{3};...
                           tool.NPlanes{2} 1               tool.PlaneIndex{3};...
                           tool.NPlanes{2} tool.NPlanes{1} tool.PlaneIndex{3};...
                           1               tool.NPlanes{1} tool.PlaneIndex{3}];
            
            dwidth = 300;
            dborder = 10;
            cwidth = dwidth-2*dborder;
            cheight = 20;
            shiftUp = cheight+2*dborder;
            
            tool.Dialog = dialog('WindowStyle', 'normal',...
                                'Name', 'VolumeCropTool',...
                                'CloseRequestFcn', @tool.closeTool,...
                                'Position',[100 100 dwidth 8*dborder+8*cheight+2.5*shiftUp]);
            
            % y slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','y','Position',[dborder 6*dborder+6*cheight+1.5*shiftUp 20 cheight],'HorizontalAlignment','left');
            tool.PlaneSlider{1} = uicontrol('Parent',tool.Dialog,'Style','slider','Min',1,'Max',tool.NPlanes{1},'Value',tool.PlaneIndex{1},'Position',[dborder+20 6*dborder+6*cheight+1.5*shiftUp cwidth-20 cheight],'Tag','ys');
            addlistener(tool.PlaneSlider{1},'Value','PostSet',@tool.continuousSliderManage);
            tool.PlaneIndexLabel{1} = uicontrol('Parent',tool.Dialog,'Style','text','String',sprintf('%d',tool.PlaneIndex{1}),'Position',[dborder 7*dborder+6*cheight-3+0.5*shiftUp 60 cheight],'HorizontalAlignment','left');
            tool.RangeSetLeft{1} = uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','[ 1','Position',[dwidth-3*dborder-3*60 7*dborder+6*cheight+0.5*shiftUp 60 cheight],'Callback',@tool.rangeSetLeft,'Tag','ylsl');
            tool.RangeSetRight{1} = uicontrol('Parent',tool.Dialog,'Style','pushbutton','String',sprintf('%d ]',tool.NPlanes{1}),'Position',[dwidth-2*dborder-2*60 7*dborder+6*cheight+0.5*shiftUp 60 cheight],'Callback',@tool.rangeSetRight,'Tag','ylsr');
                            
            % x slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','x','Position',[dborder 7*dborder+7*cheight+2.5*shiftUp 20 cheight],'HorizontalAlignment','left');
            tool.PlaneSlider{2} = uicontrol('Parent',tool.Dialog,'Style','slider','Min',1,'Max',tool.NPlanes{2},'Value',tool.PlaneIndex{2},'Position',[dborder+20 7*dborder+7*cheight+2.5*shiftUp cwidth-20 cheight],'Tag','xs');
            addlistener(tool.PlaneSlider{2},'Value','PostSet',@tool.continuousSliderManage);
            tool.PlaneIndexLabel{2} = uicontrol('Parent',tool.Dialog,'Style','text','String',sprintf('%d',tool.PlaneIndex{2}),'Position',[dborder 8*dborder+7*cheight-3+1.5*shiftUp 60 cheight],'HorizontalAlignment','left');
            tool.RangeSetLeft{2} = uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','[ 1','Position',[dwidth-3*dborder-3*60 8*dborder+7*cheight+1.5*shiftUp 60 cheight],'Callback',@tool.rangeSetLeft,'Tag','xlsl');
            tool.RangeSetRight{2} = uicontrol('Parent',tool.Dialog,'Style','pushbutton','String',sprintf('%d ]',tool.NPlanes{2}),'Position',[dwidth-2*dborder-2*60 8*dborder+7*cheight+1.5*shiftUp 60 cheight],'Callback',@tool.rangeSetRight,'Tag','xlsr');
                            
            % z slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','z','Position',[dborder 5*dborder+5*cheight+0.5*shiftUp 20 cheight],'HorizontalAlignment','left');
            tool.PlaneSlider{3} = uicontrol('Parent',tool.Dialog,'Style','slider','Min',1,'Max',tool.NPlanes{3},'Value',tool.PlaneIndex{3},'Position',[dborder+20 5*dborder+5*cheight+0.5*shiftUp cwidth-20 cheight],'Tag','zs');
            addlistener(tool.PlaneSlider{3},'Value','PostSet',@tool.continuousSliderManage);
            tool.PlaneIndexLabel{3} = uicontrol('Parent',tool.Dialog,'Style','text','String',sprintf('%d',tool.PlaneIndex{3}),'Position',[dborder 6*dborder+5*cheight-3-0.5*shiftUp 60 cheight],'HorizontalAlignment','left');
            tool.RangeSetLeft{3} = uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','[ 1','Position',[dwidth-3*dborder-3*60 6*dborder+5*cheight-0.5*shiftUp 60 cheight],'Callback',@tool.rangeSetLeft,'Tag','zlsl');
            tool.RangeSetRight{3} = uicontrol('Parent',tool.Dialog,'Style','pushbutton','String',sprintf('%d ]',tool.NPlanes{3}),'Position',[dwidth-2*dborder-2*60 6*dborder+5*cheight-0.5*shiftUp 60 cheight],'Callback',@tool.rangeSetRight,'Tag','zlsr');

            % lower threshold slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','_t','Position',[dborder 4*dborder+3*cheight 20 cheight],'HorizontalAlignment','left');
            tool.LowerThresholdSlider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0,'Max',1,'Value',tool.LowerThreshold,'Position',[dborder+20 4*dborder+3*cheight cwidth-20 cheight],'Tag','lts');
            addlistener(tool.LowerThresholdSlider,'Value','PostSet',@tool.continuousSliderManage);
            
            % upper threshold slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','^t','Position',[dborder 3*dborder+2*cheight 20 cheight],'HorizontalAlignment','left');
            tool.UpperThresholdSlider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0,'Max',1,'Value',tool.UpperThreshold,'Position',[dborder+20 3*dborder+2*cheight cwidth-20 cheight],'Tag','uts');
            addlistener(tool.UpperThresholdSlider,'Value','PostSet',@tool.continuousSliderManage);
            
            % done button
            buttonDoneLabel = 'Crop';
            uicontrol('Parent',tool.Dialog,'Style','pushbutton','String',buttonDoneLabel,'Position',[dborder+20 dborder cwidth-20 2*cheight],'Callback',@tool.buttonDonePushed);
            
            % context figure
            position = [tool.Figure{3}.Position(1)+30 tool.Figure{3}.Position(2)-30 tool.Figure{3}.Position(3) tool.Figure{3}.Position(4)];
            tool.FigureContext = figure('Name','3D Context','NumberTitle','off','Position',position,'CloseRequestFcn',@tool.closeTool);
            tool.PlaneXHandle = fill3(tool.PlaneX(:,1),tool.PlaneX(:,2),tool.PlaneX(:,3),'r'); hold on
            tool.PlaneYHandle = fill3(tool.PlaneY(:,1),tool.PlaneY(:,2),tool.PlaneY(:,3),'g');
            tool.PlaneZHandle = fill3(tool.PlaneZ(:,1),tool.PlaneZ(:,2),tool.PlaneZ(:,3),'b'); hold off, alpha(0.1)
            axis off, axis equal, view(-15,-60)
            tool.PlaneXLabel = text(tool.PlaneX(1,1),tool.PlaneX(1,2),tool.PlaneX(1,3),sprintf('x = %d', tool.PlaneIndex{2}));
            tool.PlaneYLabel = text(tool.PlaneY(2,1),tool.PlaneY(2,2),tool.PlaneY(2,3),sprintf('y = %d', tool.PlaneIndex{1}));
            tool.PlaneZLabel = text(tool.PlaneZ(3,1),tool.PlaneZ(3,2),tool.PlaneZ(3,3),sprintf('z = %d', tool.PlaneIndex{3}));
                        
%             uiwait(tool.Dialog)
        end
        
        function rangeSetLeft(tool,src,~)
            switch src.Tag
                case 'ylsl'
                    sIndex = 1;
                case 'xlsl'
                    sIndex = 2;
                case 'zlsl'
                    sIndex = 3;
            end
            tool.RangeSetLeft{sIndex}.String = sprintf('[ %d',tool.PlaneIndex{sIndex});
        end
        
        function rangeSetRight(tool,src,~)
            switch src.Tag
                case 'ylsr'
                    sIndex = 1;
                case 'xlsr'
                    sIndex = 2;
                case 'zlsr'
                    sIndex = 3;
            end
            tool.RangeSetRight{sIndex}.String = sprintf('%d ]',tool.PlaneIndex{sIndex});
        end
        
        function continuousSliderManage(tool,~,callbackdata)
            tag = callbackdata.AffectedObject.Tag;
            value = callbackdata.AffectedObject.Value;
            if strcmp(tag,'uts') || strcmp(tag,'lts')
                if strcmp(tag,'uts')
                    tool.UpperThreshold = value;
                elseif strcmp(tag,'lts')
                    tool.LowerThreshold = value;
                end
                
                I = tool.Volume(tool.PlaneIndex{1},:,:);
                I = reshape(I,[tool.NPlanes{2} tool.NPlanes{3}]);
                tool.PlaneHandle{1}.CData = tool.applyThresholds(I);
                
                I = tool.Volume(:,tool.PlaneIndex{2},:);
                I = reshape(I,[tool.NPlanes{1} tool.NPlanes{3}]);
                tool.PlaneHandle{2}.CData = tool.applyThresholds(I);
                
                I = tool.Volume(:,:,tool.PlaneIndex{3});
                tool.PlaneHandle{3}.CData = tool.applyThresholds(I);
            elseif strcmp(tag,'ys') || strcmp(tag,'xs') || strcmp(tag,'zs')
                if strcmp(tag,'ys')
                    tool.PlaneIndex{1} = round(value);
                    tool.PlaneY(:,2) = tool.PlaneIndex{1}; tool.PlaneYHandle.Vertices = tool.PlaneY;
                    
                    I = tool.Volume(tool.PlaneIndex{1},:,:);
                    I = reshape(I,[tool.NPlanes{2} tool.NPlanes{3}]);
                    tool.PlaneHandle{1}.CData = tool.applyThresholds(I);
                    
                    tool.PlaneIndexLabel{1}.String = sprintf('%d', tool.PlaneIndex{1});
                    tool.PlaneYLabel.Position = [tool.PlaneY(2,1),tool.PlaneY(2,2),tool.PlaneY(2,3)];
                    tool.PlaneYLabel.String = sprintf('y = %d', tool.PlaneIndex{1});
                    
                    tool.HLineHandle{2}.YData = [tool.PlaneIndex{1} tool.PlaneIndex{1}];
                    tool.HLineHandle{3}.YData = [tool.PlaneIndex{1} tool.PlaneIndex{1}];
                elseif strcmp(tag,'xs')
                    tool.PlaneIndex{2} = round(value);
                    tool.PlaneX(:,1) = tool.PlaneIndex{2}; tool.PlaneXHandle.Vertices = tool.PlaneX;
                    
                    I = tool.Volume(:,tool.PlaneIndex{2},:);
                    I = reshape(I,[tool.NPlanes{1} tool.NPlanes{3}]);
                    tool.PlaneHandle{2}.CData = tool.applyThresholds(I);
                    
                    tool.PlaneIndexLabel{2}.String = sprintf('%d', tool.PlaneIndex{2});
                    tool.PlaneXLabel.Position = [tool.PlaneX(1,1),tool.PlaneX(1,2),tool.PlaneX(1,3)];
                    tool.PlaneXLabel.String = sprintf('x = %d', tool.PlaneIndex{2});
                    
                    tool.HLineHandle{1}.YData = [tool.PlaneIndex{2} tool.PlaneIndex{2}];
                    tool.VLineHandle{3}.XData = [tool.PlaneIndex{2} tool.PlaneIndex{2}];
                elseif strcmp(tag,'zs')
                    tool.PlaneIndex{3} = round(value);
                    tool.PlaneZ(:,3) = tool.PlaneIndex{3}; tool.PlaneZHandle.Vertices = tool.PlaneZ;
                    
                    I = tool.Volume(:,:,tool.PlaneIndex{3});
                    tool.PlaneHandle{3}.CData = tool.applyThresholds(I);
                    
                    tool.PlaneIndexLabel{3}.String = sprintf('%d', tool.PlaneIndex{3});
                    tool.PlaneZLabel.Position = [tool.PlaneZ(3,1),tool.PlaneZ(3,2),tool.PlaneZ(3,3)];
                    tool.PlaneZLabel.String = sprintf('z = %d', tool.PlaneIndex{3});
                    
                    tool.VLineHandle{1}.XData = [tool.PlaneIndex{3} tool.PlaneIndex{3}];
                    tool.VLineHandle{2}.XData = [tool.PlaneIndex{3} tool.PlaneIndex{3}];
                end
            end
        end
        
        function T = applyThresholds(tool,I)
            T = I;
            T(T < tool.LowerThreshold) = tool.LowerThreshold;
            T(T > tool.UpperThreshold) = tool.UpperThreshold;
            T = T-min(T(:));
            T = T/max(T(:));
        end
        
        function closeTool(tool,~,~)
            for i = 1:3
                delete(tool.Figure{i});
            end
            delete(tool.FigureContext);
            delete(tool.Dialog);
        end
        
        function buttonDonePushed(tool,~,~)
            ranges = zeros(3,2);
            for dIndex = 1:3
                iLeft = str2double(tool.RangeSetLeft{dIndex}.String(3:end));
                iRight = str2double(tool.RangeSetRight{dIndex}.String(1:end-2));
                ranges(dIndex,:) = [iLeft iRight];
            end
            tool.Ranges = ranges;
            tool.SubVolume = tool.Volume(ranges(1,1):ranges(1,2),ranges(2,1):ranges(2,2),ranges(3,1):ranges(3,2));
            tool.closeTool();
        end
    end
end
