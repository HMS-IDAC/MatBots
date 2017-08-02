classdef siameseThresholdSegmentationTool < handle
    properties
        FigureImages
        AxisImage
        HandleImage
        HandleMask
        Image
        BlurredImage
        ThresholdImage
        WatershedImage
        Sigma
        SegmentationThreshold
        ThrImhmin
        Dialog
        LowerThreshold
        UpperThreshold
        FragmentationText
        ThresholdText
        CheckboxOverlaySegmentation
        CheckboxOverlayFiltering
        CheckboxOverlayGrowShrink
        SliderL
        SliderU
        ThrModel
    end
    
    methods
        function tool = siameseThresholdSegmentationTool(I1,I2)
            tool.Image{1} = I1;
            tool.Image{2} = I2;
            tool.Sigma = 1;
            tool.SegmentationThreshold = 0.5;
            tool.ThrImhmin = 0.1;
            
            % setting up defaults
            tool.ThrModel.Sigma = tool.Sigma;
            tool.ThrModel.Threshold = tool.SegmentationThreshold;
            tool.ThrModel.ThrImhmin = tool.ThrImhmin;
            
            ss = get(0,'ScreenSize'); % [left botton width height]
            tool.FigureImages = figure('Position',[ss(3)/4 ss(4)/4 ss(3)/2 ss(4)/2],...
                'NumberTitle','off', 'Name','Segmentation', 'CloseRequestFcn',@tool.closeFigure, 'Resize','on');
            
            tool.AxisImage{1} = axes('Parent',tool.FigureImages,'Position',[0.01 0.01 0.48 0.98]);
            tool.HandleImage{1} = imshow(tool.Image{1});
            hold on
            ColorMask = zeros(size(tool.Image{1},1),size(tool.Image{1},2),3); ColorMask(:,:,3) = 1;
            tool.HandleMask{1} = imshow(ColorMask);
            tool.HandleMask{1}.AlphaData = zeros(size(tool.Image{1}));
            hold off
            
            tool.AxisImage{2} = axes('Parent',tool.FigureImages,'Position',[0.51 0.01 0.48 0.98]);
            tool.HandleImage{2} = imshow(tool.Image{2});
            hold on
            ColorMask = zeros(size(tool.Image{2},1),size(tool.Image{2},2),3); ColorMask(:,:,3) = 1;
            tool.HandleMask{2} = imshow(ColorMask);
            tool.HandleMask{2}.AlphaData = zeros(size(tool.Image{2}));
            hold off
            
            dwidth = 200;
            dborder = 10;
            cwidth = dwidth-2*dborder;
            cheight = 20;
            
            tool.Dialog = dialog('WindowStyle', 'normal',...
                                'Name', 'Segmentation',...
                                'CloseRequestFcn', @tool.closeDialog,...
                                'Position',[100 100 dwidth 13*dborder+14*cheight]);
            
            % change image
            uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','Change Left','Position',[dborder 12*dborder+13*cheight (dwidth-3*dborder)/2 cheight],'Callback',@tool.changeImage,'Tag','changeImageLeft');
            uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','Change Right','Position', [2*dborder+(dwidth-3*dborder)/2 12*dborder+13*cheight (dwidth-3*dborder)/2 cheight],'Callback',@tool.changeImage,'Tag','changeImageRight');
                            
            % sigma popup
            uicontrol('Parent',tool.Dialog,'Style','text','String','Smoothing','Position',[dborder 11*dborder+11*cheight cwidth cheight],'HorizontalAlignment','left');
            labels = cell(1,5);
            for i = 1:5
                labels{i} = sprintf('Sigma = %d',i);
            end
            uicontrol('Parent',tool.Dialog,'Style','popupmenu','String',labels,'Position', [dborder 10*dborder+10*cheight+10 cwidth cheight],'Callback',@tool.popupManage);
            
            % segmentation slider
            tool.ThresholdText = uicontrol('Parent',tool.Dialog,'Style','text','String',sprintf('Threshold: %.02f',tool.SegmentationThreshold),'Position',[dborder 9*dborder+9*cheight cwidth cheight],'HorizontalAlignment','left');
            Slider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0.01,'Max',0.99,'Value',tool.SegmentationThreshold,'Position',[dborder 8*dborder+8*cheight+10 cwidth cheight],'Tag','sts');
            addlistener(Slider,'Value','PostSet',@tool.continuousSliderManage);
            
            % watershed slider
            tool.FragmentationText = uicontrol('Parent',tool.Dialog,'Style','text','String',sprintf('Fragmentation: %.02f',1-tool.ThrImhmin),'Position',[dborder 7*dborder+7*cheight cwidth cheight],'HorizontalAlignment','left');
            Slider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0.01,'Max',0.99,'Value',1-tool.ThrImhmin,'Position',[dborder 6*dborder+6*cheight+10 cwidth cheight],'Tag','wts');
            addlistener(Slider,'Value','PostSet',@tool.continuousSliderManage);                
            
            % segment
            uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','Segment','Position',[dborder 5*dborder+5*cheight cwidth cheight],'Callback',@tool.buttonSegmentPushed);
            % overlay segmentation checkbox
            tool.CheckboxOverlaySegmentation = uicontrol('Parent',tool.Dialog,'Style','checkbox','String','Overlay output on image','Position',[dborder 4*dborder+4*cheight+10 cwidth cheight],'Callback',@tool.checkboxOverlaySegmentationClicked);
            
            % lower/upper threshold slider
            tool.LowerThreshold = 0;
            tool.SliderL = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0,'Max',1,'Value',tool.LowerThreshold,'Position',[dborder 3*dborder+3*cheight-10 cwidth cheight],'Tag','lts');
            addlistener(tool.SliderL,'Value','PostSet',@tool.continuousSliderManage);
            tool.UpperThreshold = 1;
            tool.SliderU = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0,'Max',1,'Value',tool.UpperThreshold,'Position',[dborder 2*dborder+2*cheight cwidth cheight],'Tag','uts');
            addlistener(tool.SliderU,'Value','PostSet', @tool.continuousSliderManage);
            
            % quit
            uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','Done','Position',[dborder dborder cwidth 2*cheight],'Callback',@tool.buttonSetParametersPushed);
           
            uiwait(tool.Dialog)
        end
        
        function changeImage(tool,src,callbackdata)
            [filename, pathname] = uigetfile({'*.tif;*.jpg;*.png','Images (.tif, .jpg, .png)'});
            if filename ~= 0
                I = imreadGrayscaleDouble([pathname filesep filename]);
                if strcmp(src.Tag,'changeImageLeft')
                    tool.Image{1} = I;
                    tool.HandleImage{1}.CData = I;
                    tool.HandleImage{2}.CData = tool.Image{2};
                elseif strcmp(src.Tag,'changeImageRight')
                    tool.Image{2} = I;
                    tool.HandleImage{2}.CData = I;
                    tool.HandleImage{1}.CData = tool.Image{1};
                end
            end
            for i = 1:2
                tool.HandleMask{i}.AlphaData = 0;
            end
            tool.WatershedImage = [];
            tool.CheckboxOverlaySegmentation.Value = 0;
            tool.LowerThreshold = 0; tool.UpperThreshold = 1;
            tool.SliderL.Value = 0; tool.SliderU.Value = 1;
        end
        
        function checkboxOverlaySegmentationClicked(tool,src,callbackdata)
            if ~isempty(tool.WatershedImage)
                if src.Value == 1
                    tool.HandleMask{1}.AlphaData = 0.5*tool.WatershedImage{1};
                    tool.HandleMask{2}.AlphaData = 0.5*tool.WatershedImage{2};
                elseif src.Value == 0
                    tool.HandleMask{1}.AlphaData = 0;%zeros(size(tool.WatershedImage{1}));
                    tool.HandleMask{2}.AlphaData = 0;%zeros(size(tool.WatershedImage{2}));
                end
            end
        end
        
        function popupManage(tool,src,callbackdata)
            tool.Sigma = src.Value;
        end
        
        function continuousSliderManage(tool,src,callbackdata)
            tag = callbackdata.AffectedObject.Tag;
            value = callbackdata.AffectedObject.Value;
            
            if strcmp(tag,'wts')
                tool.ThrImhmin = 1-value;
                tool.FragmentationText.String = sprintf('Fragmentation: %.02f',1-tool.ThrImhmin);
            elseif strcmp(tag,'sts')
                tool.SegmentationThreshold = value;
                tool.ThresholdText.String = sprintf('Threshold: %.02f',tool.SegmentationThreshold);
            else
                if strcmp(tag,'uts')
                    tool.UpperThreshold = value;
                elseif strcmp(tag,'lts')
                    tool.LowerThreshold = value;
                end
                for i = 1:2
                    I = tool.Image{i};
                    I(I < tool.LowerThreshold) = tool.LowerThreshold;
                    I(I > tool.UpperThreshold) = tool.UpperThreshold;
                    I = I-min(I(:));
                    I = I/max(I(:));
                    tool.HandleImage{i}.CData = I;
                end
            end
        end
        
        function buttonSegmentPushed(tool,src,callbackdata)
            h = waitbar(0,'Segmenting...');
            for i = 1:2
                tool.BlurredImage{i} = filterGauss2D(tool.Image{i},tool.Sigma);
            end
            waitbar(1/3)
            for i = 1:2
                tool.ThresholdImage{i} = tool.BlurredImage{i} > tool.SegmentationThreshold;
            end
            waitbar(2/3)
            for i = 1:2
                if max(tool.ThresholdImage{i}(:)) == 0
                    tool.WatershedImage{i} = tool.ThresholdImage{i};
                else
                    tool.WatershedImage{i} = bwWatershed(tool.ThresholdImage{i},tool.ThrImhmin);
                end
                tool.HandleMask{i}.AlphaData = 0.5*tool.WatershedImage{i};
            end
            close(h)
            tool.CheckboxOverlaySegmentation.Value = 1;
            
%             figure('NumberTitle','off', 'Name','Segmentation','Position',tool.FigureImages.Position)
%             ax1 = subplot(2,3,1);
%             imshow(tool.BlurredImage{1},[])
%             ax2 = subplot(2,3,2);
%             imshow(tool.ThresholdImage{1},[])
%             ax3 = subplot(2,3,3);
%             imshow(tool.WatershedImage{1},[])
%             linkaxes([ax1, ax2, ax3],'xy')
%             ax1.Title.String = sprintf('Sigma: %d', tool.Sigma);
%             ax2.Title.String = sprintf('Threshold: %.02f', tool.SegmentationThreshold);
%             ax3.Title.String = sprintf('Fragmentation: %.02f', 1-tool.ThrImhmin);
%             ax4 = subplot(2,3,4);
%             imshow(tool.BlurredImage{2},[])
%             ax5 = subplot(2,3,5);
%             imshow(tool.ThresholdImage{2},[])
%             ax6 = subplot(2,3,6);
%             imshow(tool.WatershedImage{2},[])
%             linkaxes([ax4, ax5, ax6],'xy')
        end 
        
        function buttonSetParametersPushed(tool,src,callbackdata)
            tool.ThrModel.Sigma = tool.Sigma;
            tool.ThrModel.Threshold = tool.SegmentationThreshold;
            tool.ThrModel.ThrImhmin = tool.ThrImhmin;
            
            delete(tool.FigureImages);
            delete(tool.Dialog);
        end
        
        function closeDialog(tool,src,callbackdata)
            delete(tool.FigureImages);
            delete(tool.Dialog);
        end
        
        function closeFigure(tool,src,callbackdata)
            delete(tool.FigureImages);
            delete(tool.Dialog);
        end
    end
    
    methods (Static) % a.k.a. 'class' methods
        function Mask = Headless(I,thrModel)
            blurredImage = filterGauss2D(I,thrModel.Sigma);
            thresholdImage = blurredImage > thrModel.Threshold;
            if max(thresholdImage(:)) == 0
                Mask = thresholdImage;
            else
                Mask = bwWatershed(thresholdImage,thrModel.ThrImhmin);
            end
        end
    end
end
