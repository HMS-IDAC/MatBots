classdef symmetryTool < handle
    properties
        Figure
        HandleImage
        Image
        Overlay
        Dialog
        Slider
        Tform
        DoneButtonPushed
        Tx
        Ty
        Ta
        OutImage
    end
    
    methods
        function tool = symmetryTool(Image,varargin)
            tool.Image = Image;
            tool.Tform = affine2d(eye(3,3));
            tool.DoneButtonPushed = false;
            
            p = inputParser;
            p.addParameter('MaxShift',50);
            p.addParameter('MaxAngle',30);
            p.parse(varargin{:});
            p = p.Results;
            maxShift = p.MaxShift;
            maxAngle = p.MaxAngle;
            
            ss = get(0,'ScreenSize'); % [left botton width height]
            tool.Figure = figure('Position',[ss(3)/4 ss(4)/4 ss(3)/2 ss(4)/2],...
                'NumberTitle','off', 'Name','Symmetry Tool', 'CloseRequestFcn',@tool.closeFigure, 'Resize','on');
            
            vPosition = size(tool.Image,2)/2;
%             hPosition = size(tool.Image,1)/2;
            
            tool.HandleImage = imshow(tool.Image);
            hold on
            plot([vPosition vPosition], [1 size(tool.Image,1)],'y')
%             plot([1 size(tool.Image,2)], [hPosition hPosition],'y')
            hold off
            
            dwidth = 200;
            dborder = 10;
            cwidth = dwidth-2*dborder;
            cheight = 20;
            
            tool.Dialog = dialog('WindowStyle', 'normal',...
                                'Name', 'SymTool',...
                                'CloseRequestFcn', @tool.closeDialog,...
                                'Position',[100 100 dwidth 5*dborder+5*cheight]);
            
            uicontrol('Parent',tool.Dialog,'Style','text','String','x','Position',[dborder 4*dborder+4*cheight 20 cheight],'HorizontalAlignment','left');
            slider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',-maxShift,'Max',maxShift,'Value',0,'Position',[2*dborder 4*dborder+4*cheight cwidth-dborder cheight],'Tag','dx');
            addlistener(slider,'Value','PostSet',@tool.continuousSliderManage);                
            
            uicontrol('Parent',tool.Dialog,'Style','text','String','y','Position',[dborder 3*dborder+3*cheight 20 cheight],'HorizontalAlignment','left');
            slider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',-maxShift,'Max',maxShift,'Value',0,'Position',[2*dborder 3*dborder+3*cheight cwidth-dborder cheight],'Tag','dy');
            addlistener(slider,'Value','PostSet',@tool.continuousSliderManage);
            
            uicontrol('Parent',tool.Dialog,'Style','text','String','a','Position',[dborder 2*dborder+2*cheight 20 cheight],'HorizontalAlignment','left');
            slider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',-maxAngle,'Max',maxAngle,'Value',0,'Position',[2*dborder 2*dborder+2*cheight cwidth-dborder cheight],'Tag','da');
            addlistener(slider,'Value','PostSet',@tool.continuousSliderManage);
            
            % quit
            uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','Done','Position',[dborder dborder cwidth 2*cheight],'Callback',@tool.buttonDonePushed);
           
            tool.Tx = eye(3,3);
            tool.Ty = eye(3,3);
            tool.Ta = eye(3,3);
            
            uiwait(tool.Dialog)
        end
        
        function continuousSliderManage(tool,~,callbackdata)
            value = callbackdata.AffectedObject.Value;
            tag = callbackdata.AffectedObject.Tag;
            
            
            if strcmp(tag,'dx')
                tool.Tx(3,1) = value;
            elseif strcmp(tag,'dy')
                tool.Ty(3,2) = -value;
            elseif strcmp(tag,'da')
                a = -value/180*pi;
                
                mp = fliplr(size(tool.Image)/2);
                T1 = [eye(2) [0; 0]; [mp 1]];
                r = [cos(a) -sin(a); sin(a) cos(a)];
                R = [[r [0; 0]]; [0 0 1]];
                T2 = [eye(2) [0; 0]; [-mp 1]];
                
                tool.Ta = T2*R*T1;
            end
            
            
            tool.Tform = affine2d(tool.Ta*tool.Ty*tool.Tx);
            tool.OutImage = imwarp(tool.Image,tool.Tform,'OutputView',imref2d(size(tool.Image)));
            tool.HandleImage.CData = tool.OutImage;
        end
        
        function buttonDonePushed(tool,~,~)
            delete(tool.Figure);
            delete(tool.Dialog);
            tool.DoneButtonPushed = true;
        end
        
        function closeDialog(tool,~,~)
            delete(tool.Figure);
            delete(tool.Dialog);
        end
        
        function closeFigure(tool,~,~)
            delete(tool.Figure);
            delete(tool.Dialog);
        end
    end
end