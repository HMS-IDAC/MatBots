classdef volumeAnnotationToolPro < handle    
    properties
        Figure
        FigureContext
        Axis
        PlaneHandle
        TransparencyHandle
        PlaneIndex
        NPlanes
        NLabels
        LabelIndex
        Volume
        ImageSize
        LabelMasks
        MouseIsDown
        PenSize
        PenSizeText
        RadioDraw
        RadioErase
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
        DidAnnotate
        PlaneIndexLabel
        LoopSetLeft
        LoopSetRight
        Loop
        PlaneSlider
        NLoops
        LoopInterval
        Looping
        NLoopsEdit
        LoopIntervalEdit
    end
    
    methods
        function tool = volumeAnnotationToolPro(V,nLabels,varargin)
% volumeAnnotationToolPro(V,nClasses)
% A tool to annotate a 3D volume for machine learning
% V should be 'double' and in the range [0,1]
% nClasses is the number of classes (1,2,3,...)
%
% example
% -------
% load mri
% V = double(squeeze(D))/255;
% VAT = volumeAnnotationToolPro(V,2);
% % [annotate, click 'Done']
% MaskClass1 = VAT.LabelMasks(:,:,:,1);
% MaskClass2 = VAT.LabelMasks(:,:,:,2);
            
            tool.DidAnnotate = 0;
            
            tool.Volume = V;
            for i = 1:3
                tool.NPlanes{i} = size(V,i);
                tool.PlaneIndex{i} = round(tool.NPlanes{i}/2);
            end
            
            tool.NLabels = nLabels;
            tool.LabelMasks = zeros(size(V,1),size(V,2),size(V,3),nLabels);
            tool.LabelIndex = 1;
            labels = cell(1,nLabels);
            for i = 1:nLabels
                labels{i} = sprintf('Class %d',i);
            end
            
            tool.LowerThreshold = 0;
            tool.UpperThreshold = 1;
                             
            % y
            tool.Figure{1} = figure('Name','Plane Y','NumberTitle','off','CloseRequestFcn',@tool.closeTool,...
                'WindowButtonMotionFcn', @tool.mouseMove, 'WindowButtonDownFcn', @tool.mouseDown, 'WindowButtonUpFcn', @tool.mouseUp);
            tool.Axis{1} = axes('Parent',tool.Figure{1},'Position',[0 0 1 1]); % subplot(1,3,2);
            I = tool.Volume(tool.PlaneIndex{1},:,:);
            I = reshape(I,[tool.NPlanes{2} tool.NPlanes{3}]);
            tool.PlaneHandle{1} = imshow(tool.applyThresholds(I)); hold on;
            J = zeros(size(I)); J = cat(3,ones(size(I,1),size(I,2),2),J);
            tool.TransparencyHandle{1} = imshow(J); tool.TransparencyHandle{1}.AlphaData = zeros(size(I));
            tool.HLineHandle{1} = plot([1 tool.NPlanes{3}],[tool.PlaneIndex{2} tool.PlaneIndex{2}],'r');
            tool.VLineHandle{1} = plot([tool.PlaneIndex{3} tool.PlaneIndex{3}],[1 tool.NPlanes{2}],'b');  hold off;
            tool.ImageSize{1} = size(I);
            % tool.Axis{1}.Title.String = sprintf('y = %d', tool.PlaneIndex{1});
            tool.PlaneY = [1               tool.PlaneIndex{1} 1              ;...
                           tool.NPlanes{2} tool.PlaneIndex{1} 1              ;...
                           tool.NPlanes{2} tool.PlaneIndex{1} tool.NPlanes{3};...
                           1               tool.PlaneIndex{1} tool.NPlanes{3}];
               
            % x
           tool.Figure{2} = figure('Name','Plane X','NumberTitle','off','CloseRequestFcn',@tool.closeTool,...
                'Position',[tool.Figure{1}.Position(1)+30 tool.Figure{1}.Position(2)-30 tool.Figure{1}.Position(3) tool.Figure{1}.Position(4)],...
                'WindowButtonMotionFcn', @tool.mouseMove, 'WindowButtonDownFcn', @tool.mouseDown, 'WindowButtonUpFcn', @tool.mouseUp);
            tool.Axis{2} = axes('Parent',tool.Figure{2},'Position',[0 0 1 1]); 
            I = tool.Volume(:,tool.PlaneIndex{2},:);
            I = reshape(I,[tool.NPlanes{1} tool.NPlanes{3}]);
            tool.PlaneHandle{2} = imshow(tool.applyThresholds(I)); hold on;
            J = zeros(size(I)); J = cat(3,ones(size(I,1),size(I,2),2),J);
            tool.TransparencyHandle{2} = imshow(J); tool.TransparencyHandle{2}.AlphaData = zeros(size(I));
            tool.HLineHandle{2} = plot([1 tool.NPlanes{3}],[tool.PlaneIndex{1} tool.PlaneIndex{1}],'g');
            tool.VLineHandle{2} = plot([tool.PlaneIndex{3} tool.PlaneIndex{3}],[1 tool.NPlanes{1}],'b');  hold off;
            tool.ImageSize{2} = size(I);
            % tool.Axis{2}.Title.String = sprintf('x = %d', tool.PlaneIndex{2});
            tool.PlaneX = [tool.PlaneIndex{2} 1               1              ;...
                           tool.PlaneIndex{2} tool.NPlanes{1} 1              ;...
                           tool.PlaneIndex{2} tool.NPlanes{1} tool.NPlanes{3};...
                           tool.PlaneIndex{2} 1               tool.NPlanes{3}];
               
            % z
            tool.Figure{3} = figure('Name','Plane Z','NumberTitle','off','CloseRequestFcn',@tool.closeTool,...
                'Position',[tool.Figure{2}.Position(1)+30 tool.Figure{2}.Position(2)-30 tool.Figure{2}.Position(3) tool.Figure{2}.Position(4)],...
                'WindowButtonMotionFcn', @tool.mouseMove, 'WindowButtonDownFcn', @tool.mouseDown, 'WindowButtonUpFcn', @tool.mouseUp);
            tool.Axis{3} = axes('Parent',tool.Figure{3},'Position',[0 0 1 1]); % subplot(1,3,3);
            I = tool.Volume(:,:,tool.PlaneIndex{3});
            tool.PlaneHandle{3} = imshow(tool.applyThresholds(I)); hold on;
            J = zeros(size(I)); J = cat(3,ones(size(I,1),size(I,2),2),J);
            tool.TransparencyHandle{3} = imshow(J); tool.TransparencyHandle{3}.AlphaData = zeros(size(I));
            tool.HLineHandle{3} = plot([1 tool.NPlanes{2}],[tool.PlaneIndex{1} tool.PlaneIndex{1}],'g');
            tool.VLineHandle{3} = plot([tool.PlaneIndex{2} tool.PlaneIndex{2}],[1 tool.NPlanes{1}],'r');  hold off;
            tool.ImageSize{3} = size(I);
            % tool.Axis{3}.Title.String = sprintf('z = %d', tool.PlaneIndex{3});
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
                                'Name', 'VolumeAnnotationToolPro',...
                                'CloseRequestFcn', @tool.closeTool,...
                                'Position',[100 100 dwidth 12*dborder+14*cheight+3*shiftUp]);
            
            % pencil/eraser slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','Pencil/Eraser Size','Position',[dborder+20 10.5*dborder+13*cheight+3*shiftUp cwidth-20 cheight],'HorizontalAlignment','left');
            tool.PenSizeText = uicontrol('Parent',tool.Dialog,'Style','text','String','5','Position',[dborder+20+(cwidth-20)/2-25 11*dborder+12*cheight+3*shiftUp 50 cheight],'HorizontalAlignment','center');
            uicontrol('Parent',tool.Dialog,'Style','edit','String','10','Position',[dborder+cwidth-50 11*dborder+12*cheight+3*shiftUp 50 cheight],'HorizontalAlignment','right','Callback',@tool.changeSliderRange,'Tag','sliderMax');
            uicontrol('Parent',tool.Dialog,'Style','edit','String','1','Position',[dborder+20 11*dborder+12*cheight+3*shiftUp 50 cheight],'HorizontalAlignment','left','Callback',@tool.changeSliderRange,'Tag','sliderMin');
            tool.PenSize = 5;
            tool.Slider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',1,'Max',10,'Value',tool.PenSize,'Position',[dborder+20 11*dborder+11*cheight+3*shiftUp cwidth-20 cheight],'Callback',@tool.sliderManage,'Tag','pss');
            addlistener(tool.Slider,'Value','PostSet',@tool.continuousSliderManage);
                            
            % erase/draw
            tool.RadioDraw = uicontrol('Parent',tool.Dialog,'Style','radiobutton','Position',[dborder+20 10*dborder+10*cheight+3*shiftUp 70 cheight],'String','Draw','Callback',@tool.radioDraw);
            tool.RadioErase = uicontrol('Parent',tool.Dialog,'Style','radiobutton','Position',[dborder+90 10*dborder+10*cheight+3*shiftUp 70 cheight],'String','Erase','Callback',@tool.radioErase);
            tool.RadioDraw.Value = 1;
                            
            % class popup
            uicontrol('Parent',tool.Dialog,'Style','popupmenu','String',labels,'Position', [dborder+20 9*dborder+9*cheight+3*shiftUp cwidth-20 cheight],'Callback',@tool.popupManage);
            
            % n loops, loop interval
            tool.NLoopsEdit = uicontrol('Parent',tool.Dialog,'Style','edit','String','1','Position',[dborder+20 8*dborder+8*cheight+2.5*shiftUp 50 cheight],'HorizontalAlignment','left');
            uicontrol('Parent',tool.Dialog,'Style','text','String','# loops','Position',[dborder+70 8*dborder+8*cheight+2.5*shiftUp 50 cheight],'HorizontalAlignment','left');
            tool.LoopIntervalEdit = uicontrol('Parent',tool.Dialog,'Style','edit','String','0.1','Position',[dborder+20+cwidth/2 8*dborder+8*cheight+2.5*shiftUp 50 cheight],'HorizontalAlignment','left');
            uicontrol('Parent',tool.Dialog,'Style','text','String','loop interval','Position',[dborder+70+cwidth/2 8*dborder+8*cheight+2.5*shiftUp 100 cheight],'HorizontalAlignment','left');
            
            % y slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','y','Position',[dborder 6*dborder+6*cheight+1.5*shiftUp 20 cheight],'HorizontalAlignment','left');
            tool.PlaneSlider{1} = uicontrol('Parent',tool.Dialog,'Style','slider','Min',1,'Max',tool.NPlanes{1},'Value',tool.PlaneIndex{1},'Position',[dborder+20 6*dborder+6*cheight+1.5*shiftUp cwidth-20 cheight],'Tag','ys');
            addlistener(tool.PlaneSlider{1},'Value','PostSet',@tool.continuousSliderManage);
            tool.PlaneIndexLabel{1} = uicontrol('Parent',tool.Dialog,'Style','text','String',sprintf('%d',tool.PlaneIndex{1}),'Position',[dborder 7*dborder+6*cheight-3+0.5*shiftUp 60 cheight],'HorizontalAlignment','left');
            tool.LoopSetLeft{1} = uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','[ 1','Position',[dwidth-3*dborder-3*60 7*dborder+6*cheight+0.5*shiftUp 60 cheight],'Callback',@tool.loopSetLeft,'Tag','ylsl');
            tool.LoopSetRight{1} = uicontrol('Parent',tool.Dialog,'Style','pushbutton','String',sprintf('%d ]',tool.NPlanes{1}),'Position',[dwidth-2*dborder-2*60 7*dborder+6*cheight+0.5*shiftUp 60 cheight],'Callback',@tool.loopSetRight,'Tag','ylsr');
            tool.Loop{1} = uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','Loop','Position',[dwidth-dborder-60 7*dborder+6*cheight+0.5*shiftUp 60 cheight],'Tag','ly','Callback',@tool.loop);
                            
            % x slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','x','Position',[dborder 7*dborder+7*cheight+2.5*shiftUp 20 cheight],'HorizontalAlignment','left');
            tool.PlaneSlider{2} = uicontrol('Parent',tool.Dialog,'Style','slider','Min',1,'Max',tool.NPlanes{2},'Value',tool.PlaneIndex{2},'Position',[dborder+20 7*dborder+7*cheight+2.5*shiftUp cwidth-20 cheight],'Tag','xs');
            addlistener(tool.PlaneSlider{2},'Value','PostSet',@tool.continuousSliderManage);
            tool.PlaneIndexLabel{2} = uicontrol('Parent',tool.Dialog,'Style','text','String',sprintf('%d',tool.PlaneIndex{2}),'Position',[dborder 8*dborder+7*cheight-3+1.5*shiftUp 60 cheight],'HorizontalAlignment','left');
            tool.LoopSetLeft{2} = uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','[ 1','Position',[dwidth-3*dborder-3*60 8*dborder+7*cheight+1.5*shiftUp 60 cheight],'Callback',@tool.loopSetLeft,'Tag','xlsl');
            tool.LoopSetRight{2} = uicontrol('Parent',tool.Dialog,'Style','pushbutton','String',sprintf('%d ]',tool.NPlanes{2}),'Position',[dwidth-2*dborder-2*60 8*dborder+7*cheight+1.5*shiftUp 60 cheight],'Callback',@tool.loopSetRight,'Tag','xlsr');
            tool.Loop{2} = uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','Loop','Position',[dwidth-dborder-60 8*dborder+7*cheight+1.5*shiftUp 60 cheight],'Tag','lx','Callback',@tool.loop);
                            
            % z slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','z','Position',[dborder 5*dborder+5*cheight+0.5*shiftUp 20 cheight],'HorizontalAlignment','left');
            tool.PlaneSlider{3} = uicontrol('Parent',tool.Dialog,'Style','slider','Min',1,'Max',tool.NPlanes{3},'Value',tool.PlaneIndex{3},'Position',[dborder+20 5*dborder+5*cheight+0.5*shiftUp cwidth-20 cheight],'Tag','zs');
            addlistener(tool.PlaneSlider{3},'Value','PostSet',@tool.continuousSliderManage);
            tool.PlaneIndexLabel{3} = uicontrol('Parent',tool.Dialog,'Style','text','String',sprintf('%d',tool.PlaneIndex{3}),'Position',[dborder 6*dborder+5*cheight-3-0.5*shiftUp 60 cheight],'HorizontalAlignment','left');
            tool.LoopSetLeft{3} = uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','[ 1','Position',[dwidth-3*dborder-3*60 6*dborder+5*cheight-0.5*shiftUp 60 cheight],'Callback',@tool.loopSetLeft,'Tag','zlsl');
            tool.LoopSetRight{3} = uicontrol('Parent',tool.Dialog,'Style','pushbutton','String',sprintf('%d ]',tool.NPlanes{3}),'Position',[dwidth-2*dborder-2*60 6*dborder+5*cheight-0.5*shiftUp 60 cheight],'Callback',@tool.loopSetRight,'Tag','zlsr');
            tool.Loop{3} = uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','Loop','Position',[dwidth-dborder-60 6*dborder+5*cheight-0.5*shiftUp 60 cheight],'Tag','lz','Callback',@tool.loop);

            % lower threshold slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','_t','Position',[dborder 4*dborder+3*cheight 20 cheight],'HorizontalAlignment','left');
            tool.LowerThresholdSlider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0,'Max',1,'Value',tool.LowerThreshold,'Position',[dborder+20 4*dborder+3*cheight cwidth-20 cheight],'Tag','lts');
            addlistener(tool.LowerThresholdSlider,'Value','PostSet',@tool.continuousSliderManage);
            
            % upper threshold slider
            uicontrol('Parent',tool.Dialog,'Style','text','String','^t','Position',[dborder 3*dborder+2*cheight 20 cheight],'HorizontalAlignment','left');
            tool.UpperThresholdSlider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0,'Max',1,'Value',tool.UpperThreshold,'Position',[dborder+20 3*dborder+2*cheight cwidth-20 cheight],'Tag','uts');
            addlistener(tool.UpperThresholdSlider,'Value','PostSet',@tool.continuousSliderManage);
            
            % done button
            if nargin > 2
                buttonDoneLabel = varargin{1};
            else
                buttonDoneLabel = 'Done';
            end
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
            
            tool.MouseIsDown = false;
            
            tool.NLoops = 1;
            tool.LoopInterval = 0.1;
            tool.Looping = false;
                        
%             uiwait(tool.Dialog)
        end
        
        function loop(tool,src,~)
            if not(tool.Looping)
                tool.NLoops = str2double(tool.NLoopsEdit.String);
                tool.LoopInterval = str2double(tool.LoopIntervalEdit.String);
                for i = 1:3
                    tool.Loop{i}.Enable = 'off'; 
                end
                tool.Looping = true;
                switch src.Tag
                    case 'ly'
                        sIndex = 1;
                    case 'lx'
                        sIndex = 2;
                    case 'lz'
                        sIndex = 3;
                end
                iLeft = str2double(tool.LoopSetLeft{sIndex}.String(3:end));
                iRight = str2double(tool.LoopSetRight{sIndex}.String(1:end-2));
                if iLeft >= iRight
                    uiwait(errordlg('Left limit should be smaller than right limit.', 'Error'));
                end

                for j = 1:tool.NLoops
                    tool.NLoopsEdit.String = sprintf('%d/%d',j,tool.NLoops);
                    for i = iLeft:iRight
                        tool.PlaneSlider{sIndex}.Value = i;
                        pause(tool.LoopInterval);
                    end
                    for i = iRight:-1:iLeft
                        tool.PlaneSlider{sIndex}.Value = i;
                        pause(tool.LoopInterval);
                    end
                end
                tool.Looping = false;
                for i = 1:3
                    tool.Loop{i}.Enable = 'on'; 
                end
                tool.NLoopsEdit.String = sprintf('%d',tool.NLoops);
            end
        end
        
        function loopSetLeft(tool,src,~)
            switch src.Tag
                case 'ylsl'
                    sIndex = 1;
                case 'xlsl'
                    sIndex = 2;
                case 'zlsl'
                    sIndex = 3;
            end
            tool.LoopSetLeft{sIndex}.String = sprintf('[ %d',tool.PlaneIndex{sIndex});
        end
        
        function loopSetRight(tool,src,~)
            switch src.Tag
                case 'ylsr'
                    sIndex = 1;
                case 'xlsr'
                    sIndex = 2;
                case 'zlsr'
                    sIndex = 3;
            end
            tool.LoopSetRight{sIndex}.String = sprintf('%d ]',tool.PlaneIndex{sIndex});
        end
        
        function changeSliderRange(tool,src,~)
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
        
        function sliderManage(tool,src,~)
            tool.PenSize = round(src.Value);
            tool.TransparencyHandle{1}.AlphaData =  0.5*reshape(tool.LabelMasks(tool.PlaneIndex{1},:,:,tool.LabelIndex),[tool.NPlanes{2} tool.NPlanes{3}]);
            tool.TransparencyHandle{2}.AlphaData =  0.5*reshape(tool.LabelMasks(:,tool.PlaneIndex{2},:,tool.LabelIndex),[tool.NPlanes{1} tool.NPlanes{3}]);
            tool.TransparencyHandle{3}.AlphaData =  0.5*tool.LabelMasks(:,:,tool.PlaneIndex{3},tool.LabelIndex);
        end
        
        function radioDraw(tool,src,~)
            tool.RadioErase.Value = 1-src.Value;
        end
        
        function radioErase(tool,src,~)
            tool.RadioDraw.Value = 1-src.Value;
        end
        
        function popupManage(tool,src,~)
            tool.LabelIndex = src.Value;
            tool.TransparencyHandle{1}.AlphaData =  0.5*reshape(tool.LabelMasks(tool.PlaneIndex{1},:,:,tool.LabelIndex),[tool.NPlanes{2} tool.NPlanes{3}]);
            tool.TransparencyHandle{2}.AlphaData =  0.5*reshape(tool.LabelMasks(:,tool.PlaneIndex{2},:,tool.LabelIndex),[tool.NPlanes{1} tool.NPlanes{3}]);
            tool.TransparencyHandle{3}.AlphaData =  0.5*tool.LabelMasks(:,:,tool.PlaneIndex{3},tool.LabelIndex);
        end
        
        function mouseDown(tool,~,~)
            tool.MouseIsDown = true;
        end
        
        function mouseUp(tool,~,~)
            tool.MouseIsDown = false;
        end
        
        function mouseMove(tool,src,~)
            if tool.MouseIsDown
                ps = tool.PenSize;

                if strcmp(src.Name,'Plane Y')
                    i = 1;
                elseif strcmp(src.Name,'Plane X')
                    i = 2;
                elseif strcmp(src.Name,'Plane Z')
                    i = 3;
                end
                p = tool.Axis{i}.CurrentPoint;
                col = round(p(1,1));
                row = round(p(1,2));
                imageSize = tool.ImageSize{i};
                if row > ps && row <= imageSize(1)-ps && col > ps && col <= imageSize(2)-ps
                    [Y,X] = meshgrid(-ps:ps,-ps:ps);
                    switch i
                        case 1
                            Curr = tool.LabelMasks(tool.PlaneIndex{1},row-ps:row+ps,col-ps:col+ps,tool.LabelIndex);
                            Mask = reshape(sqrt(X.^2+Y.^2) < ps,[1 size(Y,1) size(Y,2)]);
                            if tool.RadioDraw.Value == 1
                                tool.LabelMasks(tool.PlaneIndex{1},row-ps:row+ps,col-ps:col+ps,tool.LabelIndex) = max(Curr,Mask);
                                tool.TransparencyHandle{1}.AlphaData(row-ps:row+ps,col-ps:col+ps) = reshape(0.5*max(Curr,Mask),size(Y));
                            elseif tool.RadioErase.Value == 1
                                tool.LabelMasks(tool.PlaneIndex{1},row-ps:row+ps,col-ps:col+ps,tool.LabelIndex) = min(Curr,1-Mask);
                                tool.TransparencyHandle{1}.AlphaData(row-ps:row+ps,col-ps:col+ps) = reshape(min(Curr,0.5*(1-Mask)),size(Y));
                            end
                        case 2
                            Curr = tool.LabelMasks(row-ps:row+ps,tool.PlaneIndex{2},col-ps:col+ps,tool.LabelIndex);
                            Mask = reshape(sqrt(X.^2+Y.^2) < ps,[size(Y,1) 1 size(Y,2)]);
                            if tool.RadioDraw.Value == 1
                                tool.LabelMasks(row-ps:row+ps,tool.PlaneIndex{2},col-ps:col+ps,tool.LabelIndex) = max(Curr,Mask);
                                tool.TransparencyHandle{2}.AlphaData(row-ps:row+ps,col-ps:col+ps) = reshape(0.5*max(Curr,Mask),size(Y));
                            elseif tool.RadioErase.Value == 1
                                tool.LabelMasks(row-ps:row+ps,tool.PlaneIndex{2},col-ps:col+ps,tool.LabelIndex) = min(Curr,1-Mask);
                                tool.TransparencyHandle{2}.AlphaData(row-ps:row+ps,col-ps:col+ps) = reshape(min(Curr,0.5*(1-Mask)),size(Y));
                            end
                        case 3
                            Curr = tool.LabelMasks(row-ps:row+ps,col-ps:col+ps,tool.PlaneIndex{3},tool.LabelIndex);
                            Mask = sqrt(X.^2+Y.^2) < ps;
                            if tool.RadioDraw.Value == 1
                                tool.LabelMasks(row-ps:row+ps,col-ps:col+ps,tool.PlaneIndex{3},tool.LabelIndex) = max(Curr,Mask);
                                tool.TransparencyHandle{3}.AlphaData(row-ps:row+ps,col-ps:col+ps) = 0.5*max(Curr,Mask);
                            elseif tool.RadioErase.Value == 1
                                tool.LabelMasks(row-ps:row+ps,col-ps:col+ps,tool.PlaneIndex{3},tool.LabelIndex) = min(Curr,1-Mask);
                                tool.TransparencyHandle{3}.AlphaData(row-ps:row+ps,col-ps:col+ps) = min(Curr,0.5*(1-Mask));
                            end
                    end
                end

            end
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
                    tool.TransparencyHandle{1}.AlphaData = reshape(0.5*tool.LabelMasks(tool.PlaneIndex{1},:,:,tool.LabelIndex),size(I));
                    
                    % tool.Axis{1}.Title.String = sprintf('y = %d', tool.PlaneIndex{1});
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
                    tool.TransparencyHandle{2}.AlphaData = reshape(0.5*tool.LabelMasks(:,tool.PlaneIndex{2},:,tool.LabelIndex),size(I));
                    
                    % tool.Axis{2}.Title.String = sprintf('x = %d', tool.PlaneIndex{2});
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
                    tool.TransparencyHandle{3}.AlphaData = 0.5*tool.LabelMasks(:,:,tool.PlaneIndex{3},tool.LabelIndex);
                    
                    % tool.Axis{3}.Title.String = sprintf('z = %d', tool.PlaneIndex{3});
                    tool.PlaneIndexLabel{3}.String = sprintf('%d', tool.PlaneIndex{3});
                    tool.PlaneZLabel.Position = [tool.PlaneZ(3,1),tool.PlaneZ(3,2),tool.PlaneZ(3,3)];
                    tool.PlaneZLabel.String = sprintf('z = %d', tool.PlaneIndex{3});
                    
                    tool.VLineHandle{1}.XData = [tool.PlaneIndex{3} tool.PlaneIndex{3}];
                    tool.VLineHandle{2}.XData = [tool.PlaneIndex{3} tool.PlaneIndex{3}];
                end
            elseif strcmp(tag,'pss')
                tool.PenSize = round(callbackdata.AffectedObject.Value);
                ps = tool.PenSize;
                tool.PenSizeText.String = sprintf('%d',ps);
                [Y,X] = meshgrid(-ps:ps,-ps:ps);
                Mask = sqrt(X.^2+Y.^2) < ps;
                
                for i = 1:3
                    imageSize = tool.ImageSize{i};
                    r1 = ceil(tool.Axis{i}.YLim(1));
                    r2 = floor(tool.Axis{i}.YLim(2));
                    c1 = ceil(tool.Axis{i}.XLim(1));
                    c2 = floor(tool.Axis{i}.XLim(2));
                    rM = round(mean(tool.Axis{i}.YLim));
                    cM = round(mean(tool.Axis{i}.XLim));
                    tool.TransparencyHandle{i}.AlphaData(max(1,r1):min(imageSize(1),r2),max(1,c1):min(imageSize(2),c2)) = 0;
                    if r1 >= 1 && r2 <= imageSize(1) && c1 >= 1 && c2 <= imageSize(2) ...
                            && rM-ps >= 1 && rM+ps <= imageSize(1) && cM-ps >=1 && cM+ps <= imageSize(2)
                        tool.TransparencyHandle{i}.AlphaData(rM-ps:rM+ps,cM-ps:cM+ps) = Mask;
                    end
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
            NoOverlap = sum(tool.LabelMasks,4) <= 1;
            tool.LabelMasks = tool.LabelMasks.*repmat(NoOverlap,[1 1 1 tool.NLabels]);
            tool.DidAnnotate = 1;
            tool.closeTool();
        end
    end
end
