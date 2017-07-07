classdef imageAnnotationApp < handle    
    properties
        Figure
        Axis
        TransparencyHandle
        Image
        NLabels
        LabelIndex
        LabelMasks
        MouseIsDown
        PenSize
        Dialog
        PenMask
        RadioDraw
        RadioErase
        FolderPath
        ImageName
    end
    
    methods
        
        function app = imageAnnotationApp(imagePath,resizeFactor)
            [app.FolderPath, app.ImageName] = fileparts(imagePath);
            I = imresize(imreadGrayscaleDouble(imagePath),resizeFactor);
            
            app.LabelIndex = 1;
            app.Image = I;
            J = ones(size(app.Image));
            app.NLabels = 3;
            
            app.Figure = figure(...%'MenuBar','none', ...
                                 'NumberTitle','off', ...
                                 'Name','Image', ...
                                 'CloseRequestFcn',@app.closeFigure, ...
                                 'WindowButtonMotionFcn', @app.mouseMove, ...
                                 'WindowButtonDownFcn', @app.mouseDown, ...
                                 'WindowButtonUpFcn', @app.mouseUp, ...
                                 'Resize','on');
            app.Axis = axes('Parent',app.Figure,'Position',[0 0 1 1]);
            
            imshow(app.Image)
            hold on
            app.TransparencyHandle = imshow(J);
            hold off
            app.LabelMasks = zeros(size(app.Image,1),size(app.Image,2),app.NLabels);
            app.LabelIndex = 1;
            set(app.TransparencyHandle, 'AlphaData', zeros(size(app.Image)));
            app.MouseIsDown = false;
            
            dwidth = 200;
            dborder = 10;
            cwidth = dwidth-2*dborder;
            cheight = 20;
            
            app.Dialog = dialog('WindowStyle', 'normal',...
                                'Name', 'Main',...
                                'CloseRequestFcn', @app.closeDialog,...
                                'Position',[100 100 dwidth 5*dborder+6*cheight]);
            labels = {'background','contour','nucleus'};
            
            % done button
            uicontrol('Parent',app.Dialog,'Style','pushbutton','String','Save Labels','Position',[dborder dborder cwidth cheight],'Callback',@app.buttonDonePushed);
            
            % label popup
            uicontrol('Parent',app.Dialog,'Style','popupmenu','String',labels,'Position', [dborder 2*dborder+cheight cwidth cheight],'Callback',@app.popupManage);
            
            % pencil/eraser slider
            app.PenSize = 5;
            Slider = uicontrol('Parent',app.Dialog,'Style','slider','Min',1,'Max',10,'Value',app.PenSize,'Position',[dborder 3*dborder+2*cheight cwidth cheight],'Callback',@app.sliderManage);
            addlistener(Slider,'Value','PostSet',@app.continuousSliderManage);
            uicontrol('Parent',app.Dialog,'Style','text','String','Pencil/Eraser Size','Position',[dborder 3*dborder+3*cheight cwidth cheight],'HorizontalAlignment','left');
            
            app.PenMask = zeros(size(I));
            app.PenMask(round(size(I,1)/2),round(size(I,2)/2)) = 1;
            
            % erase/draw
            app.RadioErase = uicontrol('Parent',app.Dialog,'Style','radiobutton','Position',[dborder 4*dborder+4*cheight cwidth cheight],'String','Erase','Callback',@app.radioErase);
            app.RadioDraw = uicontrol('Parent',app.Dialog,'Style','radiobutton','Position',[dborder 4*dborder+5*cheight cwidth cheight],'String','Draw','Callback',@app.radioDraw);
            app.RadioDraw.Value = 1;
%             uicontrol('Parent',app.Dialog,'Style','text','String','Mode','Position',[dborder 4*dborder+6*cheight cwidth cheight],'HorizontalAlignment','left');

            uiwait(app.Dialog)
        end
        
        function radioDraw(app,src,callbackdata)
            app.RadioErase.Value = 1-src.Value;
        end
        
        function radioErase(app,src,callbackdata)
            app.RadioDraw.Value = 1-src.Value;
        end
        
        function continuousSliderManage(app,src,callbackdata)
            app.PenSize = round(callbackdata.AffectedObject.Value);
            set(app.TransparencyHandle, 'AlphaData', imdilate(app.PenMask,strel('disk',app.PenSize,0)));
        end
        
        function sliderManage(app,src,callbackdata)
            app.PenSize = round(src.Value);
            set(app.TransparencyHandle, 'AlphaData', 0.75*app.LabelMasks(:,:,app.LabelIndex));
        end
 
        function popupManage(app,src,callbackdata)
            app.LabelIndex = src.Value;
            set(app.TransparencyHandle, 'AlphaData', 0.75*app.LabelMasks(:,:,app.LabelIndex));
        end
        
        function closeDialog(app,src,callbackdata)
            delete(app.Dialog);
            delete(app.Figure);
        end
        
        function buttonDonePushed(app,src,callbackdata)
            NoOverlap = sum(app.LabelMasks,3) <= 1;
            for i = 1:app.NLabels
                imwrite(app.LabelMasks(:,:,i).*NoOverlap,[app.FolderPath sprintf('/%s_Class%d.png',app.ImageName,i)]);
            end
            delete(app.Dialog);
            delete(app.Figure);
        end
        
        function closeFigure(app,src,callbackdata)
            delete(app.Figure);
            delete(app.Dialog);
        end
        
        function mouseMove(app,src,callbackdata)
            p = app.Axis.CurrentPoint;
            col = round(p(1,1));
            row = round(p(1,2));
           
            ps = app.PenSize;
            if row > ps && row <= size(app.Image,1)-ps && col > ps && col <= size(app.Image,2)-ps && app.MouseIsDown
                for i = -ps:ps
                    for j = -ps:ps
                        if sqrt(i*i+j*j) < ps
                            if app.RadioDraw.Value == 1
                                app.LabelMasks(row+i,col+j,app.LabelIndex) = 1;
                            elseif app.RadioErase.Value == 1
                                app.LabelMasks(row+i,col+j,app.LabelIndex) = 0;
                            end
                        end
                    end
                end
            end
            set(app.TransparencyHandle, 'AlphaData', 0.75*app.LabelMasks(:,:,app.LabelIndex));
        end
        
        function mouseDown(app,src,callbackdata)
            app.MouseIsDown = true;
        end
        
        function mouseUp(app,src,callbackdata)
            app.MouseIsDown = false;
        end
    end
end
