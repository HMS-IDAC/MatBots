classdef volumeViewTool < handle    
    properties
        Figure
        FigureContext
        Axis
        PlaneHandle
        PlaneIndex
        NPlanes
        Volume
        Dialog
        LowerThreshold
        UpperThreshold
        LowerThresholdSlider
        UpperThresholdSlider
        PlaneX
        PlaneY
        PlaneZ
        PlaneXHandle
        PlaneYHandle
        PlaneZHandle
        PlaneXLabel
        PlaneYLabel
        PlaneZLabel
    end
    
    methods
        function tool = volumeViewTool(V)
% volumeViewTool(V)
% A tool to visualize a 3D volume.
% V should be 'double' and in the range [0,1]
            
            tool.Volume = V;
            for i = 1:3
                tool.NPlanes{i} = size(V,i);
                tool.PlaneIndex{i} = round(tool.NPlanes{i}/2);
            end
            
            ss = get(0,'ScreenSize');
            tool.Figure = figure('Position',[ss(3)/4 ss(4)/3 ss(3)/2 ss(4)/3],...
                                 'NumberTitle','off', ...
                                 'Name','Planes', ...
                                 'CloseRequestFcn',@tool.closeTool, ...
                                 'Resize','on');
            
            tool.LowerThreshold = 0;
            tool.UpperThreshold = 1;
                             
            % y
            tool.Axis{1} = subplot(1,3,2);

%             tool.PlaneHandle{1} = imshow(imrotate(reshape(tool.Volume(tool.PlaneIndex{1},:,:),[tool.NPlanes{2} tool.NPlanes{3}]),90));
            I = tool.Volume(tool.PlaneIndex{1},:,:);
            I = imrotate(reshape(I,[tool.NPlanes{2} tool.NPlanes{3}]),90);
            tool.PlaneHandle{1} = imshow(tool.applyThresholds(I));
            
            tool.Axis{1}.Title.String = sprintf('y = %d', tool.PlaneIndex{1});
            tool.PlaneY = [1               tool.PlaneIndex{1} 1              ;...
                           tool.NPlanes{2} tool.PlaneIndex{1} 1              ;...
                           tool.NPlanes{2} tool.PlaneIndex{1} tool.NPlanes{3};...
                           1               tool.PlaneIndex{1} tool.NPlanes{3}];
               
            % x
            tool.Axis{2} = subplot(1,3,1);
            
%             tool.PlaneHandle{2} = imshow(imrotate(reshape(tool.Volume(:,tool.PlaneIndex{2},:),[tool.NPlanes{1} tool.NPlanes{3}]),90));
            I = tool.Volume(:,tool.PlaneIndex{2},:);
            I = imrotate(reshape(I,[tool.NPlanes{1} tool.NPlanes{3}]),90);
            tool.PlaneHandle{2} = imshow(tool.applyThresholds(I));
            
            tool.Axis{2}.Title.String = sprintf('x = %d', tool.PlaneIndex{2});
            tool.PlaneX = [tool.PlaneIndex{2} 1               1              ;...
                           tool.PlaneIndex{2} tool.NPlanes{1} 1              ;...
                           tool.PlaneIndex{2} tool.NPlanes{1} tool.NPlanes{3};...
                           tool.PlaneIndex{2} 1               tool.NPlanes{3}];
               
            % z
            tool.Axis{3} = subplot(1,3,3);
            
%             tool.PlaneHandle{3} = imshow(tool.Volume(:,:,tool.PlaneIndex{3}));
            I = tool.Volume(:,:,tool.PlaneIndex{3});
            tool.PlaneHandle{3} = imshow(tool.applyThresholds(I));
            
            tool.Axis{3}.Title.String = sprintf('z = %d', tool.PlaneIndex{3});
            tool.PlaneZ = [1               1               tool.PlaneIndex{3};...
                           tool.NPlanes{2} 1               tool.PlaneIndex{3};...
                           tool.NPlanes{2} tool.NPlanes{1} tool.PlaneIndex{3};...
                           1               tool.NPlanes{1} tool.PlaneIndex{3}];
            
            dwidth = 300;
            dborder = 10;
            cwidth = dwidth-2*dborder;
            cheight = 20;
            
            tool.Dialog = dialog('WindowStyle', 'normal',...
                                'Name', 'VolumeViewTool',...
                                'CloseRequestFcn', @tool.closeTool,...
                                'Position',[100 100 dwidth 6*dborder+6*cheight]);
            
            % y slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','y','Position',[dborder 4*dborder+4*cheight 20 cheight]);
            slider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',1,'Max',tool.NPlanes{1},'Value',tool.PlaneIndex{1},'Position',[dborder+20 4*dborder+4*cheight cwidth-20 cheight],'Tag','ys');
            addlistener(slider,'Value','PostSet',@tool.continuousSliderManage);
                            
            % x slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','x','Position',[dborder 5*dborder+5*cheight 20 cheight]);
            slider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',1,'Max',tool.NPlanes{2},'Value',tool.PlaneIndex{2},'Position',[dborder+20 5*dborder+5*cheight cwidth-20 cheight],'Tag','xs');
            addlistener(slider,'Value','PostSet',@tool.continuousSliderManage);
                            
            % z slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','z','Position',[dborder 3*dborder+3*cheight 20 cheight]);
            slider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',1,'Max',tool.NPlanes{3},'Value',tool.PlaneIndex{3},'Position',[dborder+20 3*dborder+3*cheight cwidth-20 cheight],'Tag','zs');
            addlistener(slider,'Value','PostSet',@tool.continuousSliderManage);

            % lower threshold slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','_t','Position',[dborder 2*dborder+cheight 20 cheight]);
            tool.LowerThresholdSlider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0,'Max',1,'Value',tool.LowerThreshold,'Position',[dborder+20 2*dborder+cheight cwidth-20 cheight],'Tag','lts');
            addlistener(tool.LowerThresholdSlider,'Value','PostSet',@tool.continuousSliderManage);
            
            % upper threshold slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','^t','Position',[dborder dborder 20 cheight]);
            tool.UpperThresholdSlider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0,'Max',1,'Value',tool.UpperThreshold,'Position',[dborder+20 dborder cwidth-20 cheight],'Tag','uts');
            addlistener(tool.UpperThresholdSlider,'Value','PostSet',@tool.continuousSliderManage);
            
            tool.FigureContext = figure('Name','3D Context','NumberTitle','off',...
                                        'Position',[tool.Figure.Position(1)+tool.Figure.Position(3)+10 ...
                                                    tool.Figure.Position(2) tool.Figure.Position(4) tool.Figure.Position(4)],...
                                        'CloseRequestFcn', @tool.closeTool);
            tool.PlaneXHandle = fill3(tool.PlaneX(:,1),tool.PlaneX(:,2),tool.PlaneX(:,3),'r'); hold on
            tool.PlaneYHandle = fill3(tool.PlaneY(:,1),tool.PlaneY(:,2),tool.PlaneY(:,3),'g');
            tool.PlaneZHandle = fill3(tool.PlaneZ(:,1),tool.PlaneZ(:,2),tool.PlaneZ(:,3),'b'); hold off, alpha(0.1)
            axis off, axis equal, view(-15,-60)
            tool.PlaneXLabel = text(tool.PlaneX(1,1),tool.PlaneX(1,2),tool.PlaneX(1,3),sprintf('x = %d', tool.PlaneIndex{2}));
            tool.PlaneYLabel = text(tool.PlaneY(2,1),tool.PlaneY(2,2),tool.PlaneY(2,3),sprintf('y = %d', tool.PlaneIndex{1}));
            tool.PlaneZLabel = text(tool.PlaneZ(3,1),tool.PlaneZ(3,2),tool.PlaneZ(3,3),sprintf('z = %d', tool.PlaneIndex{3}));
            
%             uiwait(tool.Dialog)
        end
        
        function continuousSliderManage(tool,src,callbackdata)
            tag = callbackdata.AffectedObject.Tag;
            value = callbackdata.AffectedObject.Value;
            if strcmp(tag,'uts') || strcmp(tag,'lts')
                if strcmp(tag,'uts')
                    tool.UpperThreshold = value;
                elseif strcmp(tag,'lts')
                    tool.LowerThreshold = value;
                end
                
                I = tool.Volume(tool.PlaneIndex{1},:,:);
                I = imrotate(reshape(I,[tool.NPlanes{2} tool.NPlanes{3}]),90);
                tool.PlaneHandle{1}.CData = tool.applyThresholds(I);
                
                I = tool.Volume(:,tool.PlaneIndex{2},:);
                I = imrotate(reshape(I,[tool.NPlanes{1} tool.NPlanes{3}]),90);
                tool.PlaneHandle{2}.CData = tool.applyThresholds(I);
                
                I = tool.Volume(:,:,tool.PlaneIndex{3});
                tool.PlaneHandle{3}.CData = tool.applyThresholds(I);
            elseif strcmp(tag,'ys') || strcmp(tag,'xs') || strcmp(tag,'zs')
                if strcmp(tag,'ys')
                    tool.PlaneIndex{1} = round(value);
                    tool.PlaneY(:,2) = tool.PlaneIndex{1}; tool.PlaneYHandle.Vertices = tool.PlaneY;
                    
%                     tool.PlaneHandle{1}.CData = imrotate(reshape(tool.Volume(tool.PlaneIndex{1},:,:),[tool.NPlanes{2} tool.NPlanes{3}]),90);
                    I = tool.Volume(tool.PlaneIndex{1},:,:);
                    I = imrotate(reshape(I,[tool.NPlanes{2} tool.NPlanes{3}]),90);
                    tool.PlaneHandle{1}.CData = tool.applyThresholds(I);
                    
                    tool.Axis{1}.Title.String = sprintf('y = %d', tool.PlaneIndex{1});
                    tool.PlaneYLabel.Position = [tool.PlaneY(2,1),tool.PlaneY(2,2),tool.PlaneY(2,3)];
                    tool.PlaneYLabel.String = sprintf('y = %d', tool.PlaneIndex{1});
                elseif strcmp(tag,'xs')
                    tool.PlaneIndex{2} = round(value);
                    tool.PlaneX(:,1) = tool.PlaneIndex{2}; tool.PlaneXHandle.Vertices = tool.PlaneX;
                    
%                     tool.PlaneHandle{2}.CData = imrotate(reshape(tool.Volume(:,tool.PlaneIndex{2},:),[tool.NPlanes{1} tool.NPlanes{3}]),90);
                    I = tool.Volume(:,tool.PlaneIndex{2},:);
                    I = imrotate(reshape(I,[tool.NPlanes{1} tool.NPlanes{3}]),90);
                    tool.PlaneHandle{2}.CData = tool.applyThresholds(I);
                    
                    tool.Axis{2}.Title.String = sprintf('x = %d', tool.PlaneIndex{2});
                    tool.PlaneXLabel.Position = [tool.PlaneX(1,1),tool.PlaneX(1,2),tool.PlaneX(1,3)];
                    tool.PlaneXLabel.String = sprintf('x = %d', tool.PlaneIndex{2});
                elseif strcmp(tag,'zs')
                    tool.PlaneIndex{3} = round(value);
                    tool.PlaneZ(:,3) = tool.PlaneIndex{3}; tool.PlaneZHandle.Vertices = tool.PlaneZ;
                    
%                     tool.PlaneHandle{3}.CData = tool.Volume(:,:,tool.PlaneIndex{3});
                    I = tool.Volume(:,:,tool.PlaneIndex{3});
                    tool.PlaneHandle{3}.CData = tool.applyThresholds(I);
                    
                    tool.Axis{3}.Title.String = sprintf('z = %d', tool.PlaneIndex{3});
                    tool.PlaneZLabel.Position = [tool.PlaneZ(3,1),tool.PlaneZ(3,2),tool.PlaneZ(3,3)];
                    tool.PlaneZLabel.String = sprintf('z = %d', tool.PlaneIndex{3});
                end
%                 tool.LowerThreshold = 0;
%                 tool.UpperThreshold = 1;
%                 tool.LowerThresholdSlider.Value = 0;
%                 tool.UpperThresholdSlider.Value = 1;
            end
        end
        
        function T = applyThresholds(tool,I)
            T = I;
            T(T < tool.LowerThreshold) = tool.LowerThreshold;
            T(T > tool.UpperThreshold) = tool.UpperThreshold;
            T = T-min(T(:));
            T = T/max(T(:));
        end
        
        function closeTool(tool,src,callbackdata)
            delete(tool.Figure);
            delete(tool.FigureContext);
            delete(tool.Dialog);
        end
    end
end
