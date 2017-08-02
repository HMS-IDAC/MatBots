classdef thresholdSegmentationTool < handle
    properties
        FigureImage
        AxisImage
        HandleImage
        HandleMask
        Image
        BlurredImage
        ThresholdImage
        WatershedImage
        FilteredImage
        FinalMask
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
        ThrModel
    end
    
    methods
        function tool = thresholdSegmentationTool(I)
            tool.Image = I;
            tool.Sigma = 1;
            tool.SegmentationThreshold = 0.5;
            tool.ThrImhmin = 0.1;
            
            % setting up defaults
            tool.ThrModel.Sigma = tool.Sigma;
            tool.ThrModel.Threshold = tool.SegmentationThreshold;
            tool.ThrModel.ThrImhmin = tool.ThrImhmin;
            tool.ThrModel.AreaRange = [-Inf Inf];
            tool.ThrModel.EccRange = [0 1];
            tool.ThrModel.BWMorphOp = 'thicken';
            tool.ThrModel.BWMorphAmount = 0;
            
            tool.FigureImage = figure('NumberTitle','off', 'Name','Segmentation', 'CloseRequestFcn',@tool.closeFigure, 'Resize','on');
            tool.AxisImage = axes('Parent',tool.FigureImage,'Position',[0 0 1 1]);
            tool.HandleImage = imshow(tool.Image);
            hold on
            ColorMask = zeros(size(I,1),size(I,2),3); ColorMask(:,:,3) = 1;
            tool.HandleMask = imshow(ColorMask);
            tool.HandleMask.AlphaData = zeros(size(I));
            
            dwidth = 200;
            dborder = 10;
            cwidth = dwidth-2*dborder;
            cheight = 20;
            
            tool.Dialog = dialog('WindowStyle', 'normal',...
                                'Name', 'Segmentation',...
                                'CloseRequestFcn', @tool.closeDialog,...
                                'Position',[100 100 dwidth 16*dborder+15*cheight]);
            
            % watershed slider
            tool.FragmentationText = uicontrol('Parent',tool.Dialog,'Style','text','String',sprintf('Fragmentation: %.02f',1-tool.ThrImhmin),'Position',[dborder 15*dborder+14*cheight cwidth cheight],'HorizontalAlignment','left');
            Slider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0.01,'Max',0.99,'Value',1-tool.ThrImhmin,'Position',[dborder 14*dborder+13*cheight+10 cwidth cheight],'Callback',@tool.sliderManage,'Tag','wts');
            addlistener(Slider,'Value','PostSet',@tool.continuousSliderManage);                
                            
                            
            % segmentation slider
            tool.ThresholdText = uicontrol('Parent',tool.Dialog,'Style','text','String',sprintf('Threshold: %.02f',tool.SegmentationThreshold),'Position',[dborder 12*dborder+13*cheight cwidth cheight],'HorizontalAlignment','left');
            Slider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0.01,'Max',0.99,'Value',tool.SegmentationThreshold,'Position',[dborder 11*dborder+12*cheight+10 cwidth cheight],'Callback',@tool.sliderManage,'Tag','sts');
            addlistener(Slider,'Value','PostSet',@tool.continuousSliderManage);
            
            
            % sigma popup
            uicontrol('Parent',tool.Dialog,'Style','text','String','Smoothing','Position',[dborder 11*dborder+11*cheight cwidth cheight],'HorizontalAlignment','left');
            labels = cell(1,5);
            for i = 1:5
                labels{i} = sprintf('Sigma = %d',i);
            end
            uicontrol('Parent',tool.Dialog,'Style','popupmenu','String',labels,'Position', [dborder 10*dborder+10*cheight+10 cwidth cheight],'Callback',@tool.popupManage);
            
            % segment
            uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','Segment','Position',[dborder 9*dborder+9*cheight cwidth cheight],'Callback',@tool.buttonSegmentPushed);
            % overlay segmentation checkbox
            tool.CheckboxOverlaySegmentation = uicontrol('Parent',tool.Dialog,'Style','checkbox','String','Overlay output on image','Position',[dborder 8*dborder+8*cheight+10 cwidth cheight],'Callback',@tool.checkboxOverlaySegmentationClicked);
            
            
%             uicontrol('Parent',tool.Dialog,'Style','text','String','...','Position',[dborder 8*dborder+7*cheight cwidth cheight],'HorizontalAlignment','left');
            
            
            % filter
            uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','Filter','Position',[dborder 7*dborder+7*cheight-10 cwidth cheight],'Callback',@tool.buttonFilterPushed);
            % overlay filtering checkbox
            tool.CheckboxOverlayFiltering = uicontrol('Parent',tool.Dialog,'Style','checkbox','String','Overlay output on image','Position',[dborder 6*dborder+6*cheight cwidth cheight],'Callback',@tool.checkboxOverlayFilteringClicked);
            
            % grow/shrink
            uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','Grow/Shrink','Position',[dborder 6*dborder+5*cheight-10 cwidth cheight],'Callback',@tool.buttonGrowShrinkPushed);
            % grow/shrink checkbox
            tool.CheckboxOverlayGrowShrink = uicontrol('Parent',tool.Dialog,'Style','checkbox','String','Overlay output on image','Position',[dborder 5*dborder+4*cheight cwidth cheight],'Callback',@tool.checkboxOverlayGrowShrinkClicked);
            
            
%             uicontrol('Parent',tool.Dialog,'Style','text','String','...','Position',[dborder 3*dborder+3*cheight cwidth cheight],'HorizontalAlignment','left');
            
            
            % lower/upper threshold slider
            tool.LowerThreshold = 0;
            Slider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0,'Max',1,'Value',tool.LowerThreshold,'Position',[dborder 3*dborder+3*cheight-10 cwidth cheight],'Callback',@tool.sliderManage,'Tag','lts');
            addlistener(Slider,'Value','PostSet',@tool.continuousSliderManage);
            tool.UpperThreshold = 1;
            Slider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0,'Max',1,'Value',tool.UpperThreshold,'Position',[dborder 2*dborder+2*cheight cwidth cheight],'Callback',@tool.sliderManage,'Tag','uts');
            addlistener(Slider,'Value','PostSet', @tool.continuousSliderManage);
            
            % quit
            uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','Done setting parameters','Position',[dborder dborder cwidth 2*cheight],'Callback',@tool.buttonSetParametersPushed);
            
            uiwait(tool.Dialog)
        end
        
        function checkboxOverlaySegmentationClicked(tool,src,callbackdata)
            if ~isempty(tool.WatershedImage)
                if src.Value == 1
                    tool.HandleMask.AlphaData = 0.5*tool.WatershedImage;
                    tool.CheckboxOverlayFiltering.Value = 0;
                    tool.CheckboxOverlayGrowShrink.Value = 0;
                elseif src.Value == 0;
                    tool.HandleMask.AlphaData = zeros(size(tool.WatershedImage));
                end
            end
        end
        
        function checkboxOverlayFilteringClicked(tool,src,callbackdata)
            if ~isempty(tool.FilteredImage)
                if src.Value == 1
                    tool.HandleMask.AlphaData = 0.5*tool.FilteredImage;
                    tool.CheckboxOverlaySegmentation.Value = 0;
                    tool.CheckboxOverlayGrowShrink.Value = 0;
                elseif src.Value == 0;
                    tool.HandleMask.AlphaData = zeros(size(tool.FilteredImage));
                end
            end
        end
        
        function checkboxOverlayGrowShrinkClicked(tool,src,callbackdata)
            if ~isempty(tool.FinalMask)
                if src.Value == 1
                    tool.HandleMask.AlphaData = 0.5*tool.FinalMask;
                    tool.CheckboxOverlaySegmentation.Value = 0;
                    tool.CheckboxOverlayFiltering.Value = 0;
                elseif src.Value == 0;
                    tool.HandleMask.AlphaData = zeros(size(tool.FinalMask));
                end
            end
        end
        
        function popupManage(tool,src,callbackdata)
            tool.Sigma = src.Value;
        end
        
        function sliderManage(tool,src,callbackdata)
%             disp(src.Value)
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
                I = tool.Image;
                I(I < tool.LowerThreshold) = tool.LowerThreshold;
                I(I > tool.UpperThreshold) = tool.UpperThreshold;
                I = I-min(I(:));
                I = I/max(I(:));
                tool.HandleImage.CData = I;
            end
        end
        
        function buttonSegmentPushed(tool,src,callbackdata)
            h = waitbar(0,'Segmenting...');
            tool.BlurredImage = filterGauss2D(tool.Image,tool.Sigma);
            waitbar(1/3)
            tool.ThresholdImage = tool.BlurredImage > tool.SegmentationThreshold;
            waitbar(2/3)
            if max(tool.ThresholdImage(:)) == 0
                tool.WatershedImage = tool.ThresholdImage;
            else
                tool.WatershedImage = bwWatershed(tool.ThresholdImage,tool.ThrImhmin);
            end
            close(h)
            tool.FilteredImage = tool.WatershedImage;
            tool.FinalMask = tool.FilteredImage;
            
            scsz = get(0,'ScreenSize'); % scsz = [left tooltom width height]
            position = [scsz(3)/16 scsz(4)/2 14*scsz(3)/16 scsz(4)/3];
            figure('NumberTitle','off', 'Name','Segmentation','Position',position)
            ax1 = subplot(1,3,1);
            imshow(tool.BlurredImage)
            ax2 = subplot(1,3,2);
            imshow(tool.ThresholdImage)
            ax3 = subplot(1,3,3);
            imshow(tool.WatershedImage)
            linkaxes([ax1, ax2, ax3],'xy')
            ax1.Title.String = sprintf('Sigma: %d', tool.Sigma);
            ax2.Title.String = sprintf('Threshold: %.02f', tool.SegmentationThreshold);
            ax3.Title.String = sprintf('Fragmentation: %.02f', 1-tool.ThrImhmin);
            
            tool.HandleMask.AlphaData = 0.5*tool.WatershedImage;
            tool.CheckboxOverlaySegmentation.Value = 1;
            tool.CheckboxOverlayFiltering.Value = 0;
            tool.CheckboxOverlayGrowShrink.Value = 0;
        end 
        
        function buttonFilterPushed(tool,src,callbackdata)
            if isempty(tool.WatershedImage)
                uiwait(errordlg('Segment first...', 'Oops'));
            else
                tool.FigureImage.Visible = 'off';
                tool.Dialog.Visible = 'off';
                PFB = bwPropsFilterTool(tool.WatershedImage);
                if ~isempty(PFB.OutBW)
                    tool.FilteredImage = PFB.OutBW;
                    tool.FinalMask = tool.FilteredImage;
                    
                    tool.ThrModel.AreaRange = [PFB.AreaMin PFB.AreaMax];
                    tool.ThrModel.EccRange = [PFB.EccMin PFB.EccMax];
                end
                tool.FigureImage.Visible = 'on';
                tool.Dialog.Visible = 'on';
                tool.HandleMask.AlphaData = 0.5*tool.FilteredImage;
                tool.CheckboxOverlaySegmentation.Value = 0;
                tool.CheckboxOverlayFiltering.Value = 1;
                tool.CheckboxOverlayGrowShrink.Value = 0;
            end
        end
        
        function buttonGrowShrinkPushed(tool,src,callbackdata)
            if isempty(tool.WatershedImage)
                uiwait(errordlg('Segment first...', 'Oops'));
            else
                tool.FigureImage.Visible = 'off';
                tool.Dialog.Visible = 'off';
                MB = bwMorphTool(tool.FilteredImage);
                if ~isempty(MB.Output)
                    tool.FinalMask = MB.Output;
                    
                    tool.ThrModel.BWMorphOp = MB.BWMorphOp;
                    tool.ThrModel.BWMorphAmount = MB.Amount;
                end
                tool.FigureImage.Visible = 'on';
                tool.Dialog.Visible = 'on';
                tool.HandleMask.AlphaData = 0.5*tool.FinalMask;
                tool.CheckboxOverlaySegmentation.Value = 0;
                tool.CheckboxOverlayFiltering.Value = 0;
                tool.CheckboxOverlayGrowShrink.Value = 1;
            end
        end
        
        function buttonSetParametersPushed(tool,src,callbackdata)
            tool.ThrModel.Sigma = tool.Sigma;
            tool.ThrModel.Threshold = tool.SegmentationThreshold;
            tool.ThrModel.ThrImhmin = tool.ThrImhmin;
            
            delete(tool.FigureImage);
            delete(tool.Dialog);
        end
        
        function closeDialog(tool,src,callbackdata)
            delete(tool.FigureImage);
            delete(tool.Dialog);
        end
        
        function closeFigure(tool,src,callbackdata)
            delete(tool.FigureImage);
            delete(tool.Dialog);
        end
    end
    
    methods (Static) % a.k.a. 'class' methods
        function Mask = Headless(I,thrModel)
            blurredImage = filterGauss2D(I,thrModel.Sigma);
            thresholdImage = blurredImage > thrModel.Threshold;
            if max(thresholdImage(:)) == 0
                watershedImage = thresholdImage;
            else
                watershedImage = bwWatershed(thresholdImage,thrModel.ThrImhmin);
            end
            propsFiltImage = bwPropsFilterTool.Headless(watershedImage,thrModel.AreaRange,thrModel.EccRange);
            Mask = bwMorphTool.Headless(propsFiltImage,thrModel.BWMorphOp,thrModel.BWMorphAmount);
        end
    end
end
