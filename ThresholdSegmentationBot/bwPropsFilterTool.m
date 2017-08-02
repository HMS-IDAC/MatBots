classdef bwPropsFilterTool < handle
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
        function tool = bwPropsFilterTool(BW)
            tool.Image = BW;
            tool.OutBW = BW;
            tool.FilteredImage = repmat(double(tool.Image),[1 1 3]);
            tool.FilteredImage(:,:,1:2) = 0;
            
            stats = regionprops(tool.Image,'Area','Eccentricity');
            areas = cat(1,stats.Area);
            ecc = cat(1,stats.Eccentricity);
            tool.AreaMin = min(areas);
            tool.AreaMax = max(areas);
            tool.EccMin = min(ecc);
            tool.EccMax = max(ecc);
            
            tool.Figure = figure('NumberTitle','off', ...
                                'Name','Image and Selection', ...
                                'CloseRequestFcn',@tool.closeFigure, ...
                                'Resize','on');

            tool.Axis = axes('Parent',tool.Figure,'Position',[0 0 1 1]);
            tool.ImageHandle = imshow(tool.Image);
            hold on
            tool.FilteredImageHandle = imshow(tool.FilteredImage);
            tool.FilteredImageHandle.AlphaData = 0.5*ones(size(tool.Image));
            hold off
            
            dwidth = 400;
            dborder = 10;
            cwidth = dwidth-2*dborder;
            cheight = 20;
            tool.Dialog = dialog('WindowStyle', 'normal',...
                                'Name', 'Properties Filter',...
                                'CloseRequestFcn', @tool.closeDialog,...
                                'Position',[100 100 dwidth 9*dborder+7*cheight]);
            
            % close button
            uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','Save parameters and close','Position',[dborder 8*dborder+5*cheight cwidth 2*cheight],'Callback',@tool.buttonClosePushed);
                            
            % thresholds ecc
            uicontrol('Parent',tool.Dialog,'Style','text','String',sprintf('eccent.: [%.02f, %.02f]', tool.EccMin, tool.EccMax),'HorizontalAlignment','left','Position',[dborder 6*dborder+4*cheight+7 cwidth/2 cheight]);
            tool.EccText = uicontrol('Parent',tool.Dialog,'Style','text','String',sprintf('restrict to [%.02f, %.02f]', tool.EccMin, tool.EccMax),'HorizontalAlignment','right','Position',[dwidth/2 6*dborder+4*cheight+7 cwidth/2 cheight]);
            Slider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',tool.EccMin,'Max',tool.EccMax,'Value',tool.EccMin,'Position',[dborder 6*dborder+4*cheight-10 cwidth cheight],'Tag','ecc_min');
            addlistener(Slider,'Value','PostSet',@tool.continuousSliderManage);
            Slider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',tool.EccMin,'Max',tool.EccMax,'Value',tool.EccMax,'Position',[dborder 5*dborder+3*cheight cwidth cheight],'Tag','ecc_max');
            addlistener(Slider,'Value','PostSet', @tool.continuousSliderManage);
                            
            % thresholds area
            uicontrol('Parent',tool.Dialog,'Style','text','String',sprintf('area: [%.0f, %.0f]', tool.AreaMin, tool.AreaMax),'HorizontalAlignment','left','Position',[dborder 3*dborder+2*cheight+7 cwidth/2 cheight]);
            tool.AreaText = uicontrol('Parent',tool.Dialog,'Style','text','String',sprintf('restrict to [%.0f, %.0f]', tool.AreaMin, tool.AreaMax),'HorizontalAlignment','right','Position',[dwidth/2 3*dborder+2*cheight+7 cwidth/2 cheight]);
            Slider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',tool.AreaMin,'Max',tool.AreaMax,'Value',tool.AreaMin,'Position',[dborder 3*dborder+2*cheight-10 cwidth cheight],'Tag','area_min');
            addlistener(Slider,'Value','PostSet',@tool.continuousSliderManage);
            Slider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',tool.AreaMin,'Max',tool.AreaMax,'Value',tool.AreaMax,'Position',[dborder 2*dborder+cheight cwidth cheight],'Tag','area_max');
            addlistener(Slider,'Value','PostSet', @tool.continuousSliderManage);
            
            % detect button
            uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','Filter','Position',[dborder dborder cwidth cheight],'Callback',@tool.buttonFilterPushed);
            
            uiwait(tool.Dialog)
        end
        
        function buttonFilterPushed(tool,src,callbackdata)
            tool.OutBW = bwpropfilt(tool.Image, 'Area', [tool.AreaMin tool.AreaMax]);
            tool.OutBW = bwpropfilt(tool.OutBW, 'Eccentricity', [tool.EccMin tool.EccMax]);
            
            tool.FilteredImage = repmat(double(tool.OutBW),[1 1 3]);
            tool.FilteredImage(:,:,1:2) = 0;
            
            tool.FilteredImageHandle.CData = tool.FilteredImage;
        end
        
        function buttonClosePushed(tool,src,callbackdata)
            delete(tool.Figure);
            delete(tool.Dialog);
        end
        
        function closeFigure(tool,src,callbackdata)
            delete(tool.Figure);
            delete(tool.Dialog);
        end
        
        function closeDialog(tool,src,callbackdata)
            delete(tool.Figure);
            delete(tool.Dialog);
        end
        
        function continuousSliderManage(tool,src,callbackdata)
            tag = callbackdata.AffectedObject.Tag;
            value = callbackdata.AffectedObject.Value;
            if strcmp(tag,'area_min')
                tool.AreaMin = value;
                tool.AreaText.String = sprintf('restrict to [%.0f %.0f]', tool.AreaMin, tool.AreaMax);
            elseif strcmp(tag,'area_max')
                tool.AreaMax = value;
                tool.AreaText.String = sprintf('restrict to [%.0f %.0f]', tool.AreaMin, tool.AreaMax);
            elseif strcmp(tag,'ecc_min')
                tool.EccMin = value;
                tool.EccText.String = sprintf('restrict to [%.02f %.02f]', tool.EccMin, tool.EccMax);
            elseif strcmp(tag,'ecc_max')
                tool.EccMax = value;
                tool.EccText.String = sprintf('restrict to [%.02f %.02f]', tool.EccMin, tool.EccMax);
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