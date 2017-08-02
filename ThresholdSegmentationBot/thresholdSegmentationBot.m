classdef thresholdSegmentationBot < handle
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
        function bot = thresholdSegmentationBot(I)
            bot.Image = I;
            bot.Sigma = 1;
            bot.SegmentationThreshold = 0.5;
            bot.ThrImhmin = 0.1;
            
            % setting up defaults
            bot.ThrModel.Sigma = bot.Sigma;
            bot.ThrModel.Threshold = bot.SegmentationThreshold;
            bot.ThrModel.ThrImhmin = bot.ThrImhmin;
            bot.ThrModel.AreaRange = [-Inf Inf];
            bot.ThrModel.EccRange = [0 1];
            bot.ThrModel.BWMorphOp = 'thicken';
            bot.ThrModel.BWMorphAmount = 0;
            
            bot.FigureImage = figure('NumberTitle','off', 'Name','Segmentation', 'CloseRequestFcn',@bot.closeFigure, 'Resize','on');
            bot.AxisImage = axes('Parent',bot.FigureImage,'Position',[0 0 1 1]);
            bot.HandleImage = imshow(bot.Image);
            hold on
            ColorMask = zeros(size(I,1),size(I,2),3); ColorMask(:,:,3) = 1;
            bot.HandleMask = imshow(ColorMask);
            bot.HandleMask.AlphaData = zeros(size(I));
            
            dwidth = 200;
            dborder = 10;
            cwidth = dwidth-2*dborder;
            cheight = 20;
            
            bot.Dialog = dialog('WindowStyle', 'normal',...
                                'Name', 'Segmentation',...
                                'CloseRequestFcn', @bot.closeDialog,...
                                'Position',[100 100 dwidth 16*dborder+15*cheight]);
            
            % watershed slider
            bot.FragmentationText = uicontrol('Parent',bot.Dialog,'Style','text','String',sprintf('Fragmentation: %.02f',1-bot.ThrImhmin),'Position',[dborder 15*dborder+14*cheight cwidth cheight],'HorizontalAlignment','left');
            Slider = uicontrol('Parent',bot.Dialog,'Style','slider','Min',0.01,'Max',0.99,'Value',1-bot.ThrImhmin,'Position',[dborder 14*dborder+13*cheight+10 cwidth cheight],'Callback',@bot.sliderManage,'Tag','wts');
            addlistener(Slider,'Value','PostSet',@bot.continuousSliderManage);                
                            
                            
            % segmentation slider
            bot.ThresholdText = uicontrol('Parent',bot.Dialog,'Style','text','String',sprintf('Threshold: %.02f',bot.SegmentationThreshold),'Position',[dborder 12*dborder+13*cheight cwidth cheight],'HorizontalAlignment','left');
            Slider = uicontrol('Parent',bot.Dialog,'Style','slider','Min',0.01,'Max',0.99,'Value',bot.SegmentationThreshold,'Position',[dborder 11*dborder+12*cheight+10 cwidth cheight],'Callback',@bot.sliderManage,'Tag','sts');
            addlistener(Slider,'Value','PostSet',@bot.continuousSliderManage);
            
            
            % sigma popup
            uicontrol('Parent',bot.Dialog,'Style','text','String','Smoothing','Position',[dborder 11*dborder+11*cheight cwidth cheight],'HorizontalAlignment','left');
            labels = cell(1,5);
            for i = 1:5
                labels{i} = sprintf('Sigma = %d',i);
            end
            uicontrol('Parent',bot.Dialog,'Style','popupmenu','String',labels,'Position', [dborder 10*dborder+10*cheight+10 cwidth cheight],'Callback',@bot.popupManage);
            
            % segment
            uicontrol('Parent',bot.Dialog,'Style','pushbutton','String','Segment','Position',[dborder 9*dborder+9*cheight cwidth cheight],'Callback',@bot.buttonSegmentPushed);
            % overlay segmentation checkbox
            bot.CheckboxOverlaySegmentation = uicontrol('Parent',bot.Dialog,'Style','checkbox','String','Overlay output on image','Position',[dborder 8*dborder+8*cheight+10 cwidth cheight],'Callback',@bot.checkboxOverlaySegmentationClicked);
            
            
%             uicontrol('Parent',bot.Dialog,'Style','text','String','...','Position',[dborder 8*dborder+7*cheight cwidth cheight],'HorizontalAlignment','left');
            
            
            % filter
            uicontrol('Parent',bot.Dialog,'Style','pushbutton','String','Filter','Position',[dborder 7*dborder+7*cheight-10 cwidth cheight],'Callback',@bot.buttonFilterPushed);
            % overlay filtering checkbox
            bot.CheckboxOverlayFiltering = uicontrol('Parent',bot.Dialog,'Style','checkbox','String','Overlay output on image','Position',[dborder 6*dborder+6*cheight cwidth cheight],'Callback',@bot.checkboxOverlayFilteringClicked);
            
            % grow/shrink
            uicontrol('Parent',bot.Dialog,'Style','pushbutton','String','Grow/Shrink','Position',[dborder 6*dborder+5*cheight-10 cwidth cheight],'Callback',@bot.buttonGrowShrinkPushed);
            % grow/shrink checkbox
            bot.CheckboxOverlayGrowShrink = uicontrol('Parent',bot.Dialog,'Style','checkbox','String','Overlay output on image','Position',[dborder 5*dborder+4*cheight cwidth cheight],'Callback',@bot.checkboxOverlayGrowShrinkClicked);
            
            
%             uicontrol('Parent',bot.Dialog,'Style','text','String','...','Position',[dborder 3*dborder+3*cheight cwidth cheight],'HorizontalAlignment','left');
            
            
            % lower/upper threshold slider
            bot.LowerThreshold = 0;
            Slider = uicontrol('Parent',bot.Dialog,'Style','slider','Min',0,'Max',1,'Value',bot.LowerThreshold,'Position',[dborder 3*dborder+3*cheight-10 cwidth cheight],'Callback',@bot.sliderManage,'Tag','lts');
            addlistener(Slider,'Value','PostSet',@bot.continuousSliderManage);
            bot.UpperThreshold = 1;
            Slider = uicontrol('Parent',bot.Dialog,'Style','slider','Min',0,'Max',1,'Value',bot.UpperThreshold,'Position',[dborder 2*dborder+2*cheight cwidth cheight],'Callback',@bot.sliderManage,'Tag','uts');
            addlistener(Slider,'Value','PostSet', @bot.continuousSliderManage);
            
            % quit
            uicontrol('Parent',bot.Dialog,'Style','pushbutton','String','Done setting parameters','Position',[dborder dborder cwidth 2*cheight],'Callback',@bot.buttonSetParametersPushed);
            
            uiwait(bot.Dialog)
        end
        
        function checkboxOverlaySegmentationClicked(bot,src,callbackdata)
            if ~isempty(bot.WatershedImage)
                if src.Value == 1
                    bot.HandleMask.AlphaData = 0.5*bot.WatershedImage;
                    bot.CheckboxOverlayFiltering.Value = 0;
                    bot.CheckboxOverlayGrowShrink.Value = 0;
                elseif src.Value == 0;
                    bot.HandleMask.AlphaData = zeros(size(bot.WatershedImage));
                end
            end
        end
        
        function checkboxOverlayFilteringClicked(bot,src,callbackdata)
            if ~isempty(bot.FilteredImage)
                if src.Value == 1
                    bot.HandleMask.AlphaData = 0.5*bot.FilteredImage;
                    bot.CheckboxOverlaySegmentation.Value = 0;
                    bot.CheckboxOverlayGrowShrink.Value = 0;
                elseif src.Value == 0;
                    bot.HandleMask.AlphaData = zeros(size(bot.FilteredImage));
                end
            end
        end
        
        function checkboxOverlayGrowShrinkClicked(bot,src,callbackdata)
            if ~isempty(bot.FinalMask)
                if src.Value == 1
                    bot.HandleMask.AlphaData = 0.5*bot.FinalMask;
                    bot.CheckboxOverlaySegmentation.Value = 0;
                    bot.CheckboxOverlayFiltering.Value = 0;
                elseif src.Value == 0;
                    bot.HandleMask.AlphaData = zeros(size(bot.FinalMask));
                end
            end
        end
        
        function popupManage(bot,src,callbackdata)
            bot.Sigma = src.Value;
        end
        
        function sliderManage(bot,src,callbackdata)
%             disp(src.Value)
        end
        
        function continuousSliderManage(bot,src,callbackdata)
            tag = callbackdata.AffectedObject.Tag;
            value = callbackdata.AffectedObject.Value;
            
            if strcmp(tag,'wts')
                bot.ThrImhmin = 1-value;
                bot.FragmentationText.String = sprintf('Fragmentation: %.02f',1-bot.ThrImhmin);
            elseif strcmp(tag,'sts')
                bot.SegmentationThreshold = value;
                bot.ThresholdText.String = sprintf('Threshold: %.02f',bot.SegmentationThreshold);
            else
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
                bot.HandleImage.CData = I;
            end
        end
        
        function buttonSegmentPushed(bot,src,callbackdata)
            h = waitbar(0,'Segmenting...');
            bot.BlurredImage = filterGauss2D(bot.Image,bot.Sigma);
            waitbar(1/3)
            bot.ThresholdImage = bot.BlurredImage > bot.SegmentationThreshold;
            waitbar(2/3)
            if max(bot.ThresholdImage(:)) == 0
                bot.WatershedImage = bot.ThresholdImage;
            else
                bot.WatershedImage = bwWatershed(bot.ThresholdImage,bot.ThrImhmin);
            end
            close(h)
            bot.FilteredImage = bot.WatershedImage;
            bot.FinalMask = bot.FilteredImage;
            
            scsz = get(0,'ScreenSize'); % scsz = [left bottom width height]
            position = [scsz(3)/16 scsz(4)/2 14*scsz(3)/16 scsz(4)/3];
            figure('NumberTitle','off', 'Name','Segmentation','Position',position)
            ax1 = subplot(1,3,1);
            imshow(bot.BlurredImage)
            ax2 = subplot(1,3,2);
            imshow(bot.ThresholdImage)
            ax3 = subplot(1,3,3);
            imshow(bot.WatershedImage)
            linkaxes([ax1, ax2, ax3],'xy')
            ax1.Title.String = sprintf('Sigma: %d', bot.Sigma);
            ax2.Title.String = sprintf('Threshold: %.02f', bot.SegmentationThreshold);
            ax3.Title.String = sprintf('Fragmentation: %.02f', 1-bot.ThrImhmin);
            
            bot.HandleMask.AlphaData = 0.5*bot.WatershedImage;
            bot.CheckboxOverlaySegmentation.Value = 1;
            bot.CheckboxOverlayFiltering.Value = 0;
            bot.CheckboxOverlayGrowShrink.Value = 0;
        end 
        
        function buttonFilterPushed(bot,src,callbackdata)
            if isempty(bot.WatershedImage)
                uiwait(errordlg('Segment first...', 'Oops'));
            else
                bot.FigureImage.Visible = 'off';
                bot.Dialog.Visible = 'off';
                PFB = bwPropsFilterBot(bot.WatershedImage);
                if ~isempty(PFB.OutBW)
                    bot.FilteredImage = PFB.OutBW;
                    bot.FinalMask = bot.FilteredImage;
                    
                    bot.ThrModel.AreaRange = [PFB.AreaMin PFB.AreaMax];
                    bot.ThrModel.EccRange = [PFB.EccMin PFB.EccMax];
                end
                bot.FigureImage.Visible = 'on';
                bot.Dialog.Visible = 'on';
                bot.HandleMask.AlphaData = 0.5*bot.FilteredImage;
                bot.CheckboxOverlaySegmentation.Value = 0;
                bot.CheckboxOverlayFiltering.Value = 1;
                bot.CheckboxOverlayGrowShrink.Value = 0;
            end
        end
        
        function buttonGrowShrinkPushed(bot,src,callbackdata)
            if isempty(bot.WatershedImage)
                uiwait(errordlg('Segment first...', 'Oops'));
            else
                bot.FigureImage.Visible = 'off';
                bot.Dialog.Visible = 'off';
                MB = bwMorphBot(bot.FilteredImage);
                if ~isempty(MB.Output)
                    bot.FinalMask = MB.Output;
                    
                    bot.ThrModel.BWMorphOp = MB.BWMorphOp;
                    bot.ThrModel.BWMorphAmount = MB.Amount;
                end
                bot.FigureImage.Visible = 'on';
                bot.Dialog.Visible = 'on';
                bot.HandleMask.AlphaData = 0.5*bot.FinalMask;
                bot.CheckboxOverlaySegmentation.Value = 0;
                bot.CheckboxOverlayFiltering.Value = 0;
                bot.CheckboxOverlayGrowShrink.Value = 1;
            end
        end
        
        function buttonSetParametersPushed(bot,src,callbackdata)
            bot.ThrModel.Sigma = bot.Sigma;
            bot.ThrModel.Threshold = bot.SegmentationThreshold;
            bot.ThrModel.ThrImhmin = bot.ThrImhmin;
            
            delete(bot.FigureImage);
            delete(bot.Dialog);
        end
        
        function closeDialog(bot,src,callbackdata)
            delete(bot.FigureImage);
            delete(bot.Dialog);
        end
        
        function closeFigure(bot,src,callbackdata)
            delete(bot.FigureImage);
            delete(bot.Dialog);
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
            propsFiltImage = bwPropsFilterBot.Headless(watershedImage,thrModel.AreaRange,thrModel.EccRange);
            Mask = bwMorphBot.Headless(propsFiltImage,thrModel.BWMorphOp,thrModel.BWMorphAmount);
        end
    end
end
