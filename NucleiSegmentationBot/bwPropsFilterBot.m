classdef bwPropsFilterBot < handle
    properties
        AreaMin
        AreaMax
        AreaText
        EccMin
        EccMax
        EccText
        Figure
        Axis
        Image
        OutBW
        ImageHandle
        FilteredImage
        FilteredImageHandle
        Dialog
    end
    
    methods
        function bot = bwPropsFilterBot(BW)
            bot.Image = BW;
            bot.OutBW = BW;
            bot.FilteredImage = repmat(double(bot.Image),[1 1 3]);
            bot.FilteredImage(:,:,1:2) = 0;
            
            stats = regionprops(bot.Image,'Area','Eccentricity');
            areas = cat(1,stats.Area);
            ecc = cat(1,stats.Eccentricity);
            bot.AreaMin = min(areas);
            bot.AreaMax = max(areas);
            bot.EccMin = min(ecc);
            bot.EccMax = max(ecc);
            
            bot.Figure = figure('NumberTitle','off', ...
                                'Name','Image and Selection', ...
                                'CloseRequestFcn',@bot.closeFigure, ...
                                'Resize','on');

            bot.Axis = axes('Parent',bot.Figure,'Position',[0 0 1 1]);
            bot.ImageHandle = imshow(bot.Image);
            hold on
            bot.FilteredImageHandle = imshow(bot.FilteredImage);
            bot.FilteredImageHandle.AlphaData = 0.5*ones(size(bot.Image));
            hold off
            
            dwidth = 400;
            dborder = 10;
            cwidth = dwidth-2*dborder;
            cheight = 20;
            bot.Dialog = dialog('WindowStyle', 'normal',...
                                'Name', 'Properties Filter',...
                                'CloseRequestFcn', @bot.closeDialog,...
                                'Position',[100 100 dwidth 9*dborder+7*cheight]);
            
            % close button
            uicontrol('Parent',bot.Dialog,'Style','pushbutton','String','Save parameters and close','Position',[dborder 8*dborder+5*cheight cwidth 2*cheight],'Callback',@bot.buttonClosePushed);
                            
            % thresholds ecc
            uicontrol('Parent',bot.Dialog,'Style','text','String',sprintf('eccent.: [%.02f, %.02f]', bot.EccMin, bot.EccMax),'HorizontalAlignment','left','Position',[dborder 6*dborder+4*cheight+7 cwidth/2 cheight]);
            bot.EccText = uicontrol('Parent',bot.Dialog,'Style','text','String',sprintf('restrict to [%.02f, %.02f]', bot.EccMin, bot.EccMax),'HorizontalAlignment','right','Position',[dwidth/2 6*dborder+4*cheight+7 cwidth/2 cheight]);
            Slider = uicontrol('Parent',bot.Dialog,'Style','slider','Min',bot.EccMin,'Max',bot.EccMax,'Value',bot.EccMin,'Position',[dborder 6*dborder+4*cheight-10 cwidth cheight],'Tag','ecc_min');
            addlistener(Slider,'Value','PostSet',@bot.continuousSliderManage);
            Slider = uicontrol('Parent',bot.Dialog,'Style','slider','Min',bot.EccMin,'Max',bot.EccMax,'Value',bot.EccMax,'Position',[dborder 5*dborder+3*cheight cwidth cheight],'Tag','ecc_max');
            addlistener(Slider,'Value','PostSet', @bot.continuousSliderManage);
                            
            % thresholds area
            uicontrol('Parent',bot.Dialog,'Style','text','String',sprintf('area: [%.0f, %.0f]', bot.AreaMin, bot.AreaMax),'HorizontalAlignment','left','Position',[dborder 3*dborder+2*cheight+7 cwidth/2 cheight]);
            bot.AreaText = uicontrol('Parent',bot.Dialog,'Style','text','String',sprintf('restrict to [%.0f, %.0f]', bot.AreaMin, bot.AreaMax),'HorizontalAlignment','right','Position',[dwidth/2 3*dborder+2*cheight+7 cwidth/2 cheight]);
            Slider = uicontrol('Parent',bot.Dialog,'Style','slider','Min',bot.AreaMin,'Max',bot.AreaMax,'Value',bot.AreaMin,'Position',[dborder 3*dborder+2*cheight-10 cwidth cheight],'Tag','area_min');
            addlistener(Slider,'Value','PostSet',@bot.continuousSliderManage);
            Slider = uicontrol('Parent',bot.Dialog,'Style','slider','Min',bot.AreaMin,'Max',bot.AreaMax,'Value',bot.AreaMax,'Position',[dborder 2*dborder+cheight cwidth cheight],'Tag','area_max');
            addlistener(Slider,'Value','PostSet', @bot.continuousSliderManage);
            
            % detect button
            uicontrol('Parent',bot.Dialog,'Style','pushbutton','String','Filter','Position',[dborder dborder cwidth cheight],'Callback',@bot.buttonFilterPushed);
            
            uiwait(bot.Dialog)
        end
        
        function buttonFilterPushed(bot,src,callbackdata)
            bot.OutBW = bwpropfilt(bot.Image, 'Area', [bot.AreaMin bot.AreaMax]);
            bot.OutBW = bwpropfilt(bot.OutBW, 'Eccentricity', [bot.EccMin bot.EccMax]);
            
            bot.FilteredImage = repmat(double(bot.OutBW),[1 1 3]);
            bot.FilteredImage(:,:,1:2) = 0;
            
            bot.FilteredImageHandle.CData = bot.FilteredImage;
        end
        
        function buttonClosePushed(bot,src,callbackdata)
            delete(bot.Figure);
            delete(bot.Dialog);
        end
        
        function closeFigure(bot,src,callbackdata)
            delete(bot.Figure);
            delete(bot.Dialog);
        end
        
        function closeDialog(bot,src,callbackdata)
            delete(bot.Figure);
            delete(bot.Dialog);
        end
        
        function continuousSliderManage(bot,src,callbackdata)
            tag = callbackdata.AffectedObject.Tag;
            value = callbackdata.AffectedObject.Value;
            if strcmp(tag,'area_min')
                bot.AreaMin = value;
                bot.AreaText.String = sprintf('restrict to [%.0f %.0f]', bot.AreaMin, bot.AreaMax);
            elseif strcmp(tag,'area_max')
                bot.AreaMax = value;
                bot.AreaText.String = sprintf('restrict to [%.0f %.0f]', bot.AreaMin, bot.AreaMax);
            elseif strcmp(tag,'ecc_min')
                bot.EccMin = value;
                bot.EccText.String = sprintf('restrict to [%.02f %.02f]', bot.EccMin, bot.EccMax);
            elseif strcmp(tag,'ecc_max')
                bot.EccMax = value;
                bot.EccText.String = sprintf('restrict to [%.02f %.02f]', bot.EccMin, bot.EccMax);
            end
        end
    end
    
    methods (Static)
        function Mask = Headless(BW,areaRange,eccRange)
            Mask = bwpropfilt(BW, 'Area', areaRange);
            Mask = bwpropfilt(Mask, 'Eccentricity', eccRange);
        end
    end
end