classdef advSpotDetectionBot < handle    
    properties
        Prmts
        Figure
        Axis
        Bxis
        ImageHandle
        BoxHandle
        SpotsHandle
        Stack
        Image
        Spots
        SpotsCoord
        ChannelIndex
        Channels
        MouseIsDown
        p0
        p1
        Dialog
        LowerThreshold
        UpperThreshold
        LowerThresholdSlider
        UpperThresholdSlider
        CheckboxOverlay
        CheckboxUseChannel
        ThrText
        ThrEdit
        SigmaText
        SigmaEdit
        SDThr
        SDSigma
    end
    
    methods
        function bot = advSpotDetectionBot(S,nucleiChannel)
            channels = 1:size(S,3);
            channels(nucleiChannel) = [];
            bot.Channels = channels;
            nChannels = length(channels);
            
            bot.Prmts = zeros(nChannels,4); % channel, use, sigma, threshold (alpha)
            bot.SDSigma = 2.0;
            bot.SDThr = 0.01;
            for i = 1:nChannels
                bot.Prmts(i,1) = channels(i);
                bot.Prmts(i,2) = 1;
                bot.Prmts(i,3) = bot.SDSigma;
                bot.Prmts(i,4) = bot.SDThr;
            end
            
            bot.Stack = S;
            bot.ChannelIndex = 1;
            bot.Image = S(:,:,bot.Channels(bot.ChannelIndex));
            
            bot.Figure = figure('NumberTitle','off', ...
                                'Name','Spot Detection', ...
                                'CloseRequestFcn',@bot.closeFigure, ...
                                'WindowButtonMotionFcn', @bot.mouseMove, ...
                                'WindowButtonDownFcn', @bot.mouseDown, ...
                                'WindowButtonUpFcn', @bot.mouseUp, ...
                                'Resize','on');

            bot.Axis = axes('Parent',bot.Figure,'Position',[0 0 1 1]);
            bot.ImageHandle = imshow(bot.Image);
            hold on
            bot.BoxHandle = plot([-2 -1],[-2 -1],'-y'); % placeholder, outside view, just to get BoxHandle
            bot.SpotsHandle = plot(-1,-1,'o'); % placeholder, outside view, just to get SpotsHandle
            hold off
            bot.MouseIsDown = false;
            
            dwidth = 300;
            dborder = 10;
            cwidth = dwidth-2*dborder;
            cheight = 20;
            
            bot.Dialog = dialog('WindowStyle', 'normal',...
                                'Name', 'Spot Detection',...
                                'CloseRequestFcn', @bot.closeDialog,...
                                'Position',[100 100 dwidth 10*dborder+10*cheight]);
            
            
            % spot channel popup
            labels = cell(1,nChannels);
            for i = 1:nChannels
                labels{i} = sprintf('Channel %d',channels(i));
            end
            uicontrol('Parent',bot.Dialog,'Style','popupmenu','String',labels,'Position',[dborder 9*dborder+9*cheight cwidth cheight],'Callback',@bot.popupManage);
                            
            % use channel checkbox
            bot.CheckboxUseChannel = uicontrol('Parent',bot.Dialog,'Style','checkbox','String','Use this channel when scoring.','Value',1,'Position',[dborder 8*dborder+8*cheight cwidth cheight],'Callback',@bot.checkboxUseChannelClicked);            
            
            % spot det. alpha
            bot.ThrEdit = uicontrol('Parent',bot.Dialog,'Style','edit','String',sprintf('%.02f', bot.SDThr),'HorizontalAlignment','left','Position',[2*dborder+(cwidth-dborder)/2 7*dborder+7*cheight (cwidth-dborder)/2 cheight],'Callback',@bot.editThr);
            bot.ThrText = uicontrol('Parent',bot.Dialog,'Style','text','String',sprintf('alpha: %f', bot.SDThr),'HorizontalAlignment','left','Position',[2*dborder+(cwidth-dborder)/2 7*dborder+6*cheight (cwidth-dborder)/2 cheight]);
                            
            % sigma
            bot.SigmaEdit = uicontrol('Parent',bot.Dialog,'Style','edit','String',sprintf('%.02f', bot.SDSigma),'HorizontalAlignment','left','Position',[dborder 7*dborder+7*cheight (cwidth-dborder)/2 cheight],'Callback',@bot.editSigma);
            bot.SigmaText = uicontrol('Parent',bot.Dialog,'Style','text','String',sprintf('sigma: %.02f', bot.SDSigma),'HorizontalAlignment','left','Position',[dborder 7*dborder+6*cheight (cwidth-dborder)/2 cheight]);
            
            % detect button
            uicontrol('Parent',bot.Dialog,'Style','pushbutton','String','Detect Spots','Position',[dborder 6*dborder+5*cheight cwidth cheight],'Callback',@bot.buttonDetectSpotsPushed);
            
            % overlay checkbox
            bot.CheckboxOverlay = uicontrol('Parent',bot.Dialog,'Style','checkbox','String','Overlay spots on raw image.','Position',[dborder 5*dborder+4*cheight cwidth cheight],'Callback',@bot.checkboxOverlayClicked);
            
            % lower threshold slider
            bot.LowerThreshold = 0;
            bot.LowerThresholdSlider = uicontrol('Parent',bot.Dialog,'Style','slider','Min',0,'Max',1,'Value',bot.LowerThreshold,'Position',[dborder 3*dborder+3*cheight-10 cwidth cheight],'Tag','lts');
            addlistener(bot.LowerThresholdSlider,'Value','PostSet',@bot.continuousSliderManage);
            
            % upper threshold slider
            bot.UpperThreshold = 1;
            bot.UpperThresholdSlider = uicontrol('Parent',bot.Dialog,'Style','slider','Min',0,'Max',1,'Value',bot.UpperThreshold,'Position',[dborder 2*dborder+2*cheight cwidth cheight],'Tag','uts');
            addlistener(bot.UpperThresholdSlider,'Value','PostSet',@bot.continuousSliderManage);
            
            % quit button
            uicontrol('Parent',bot.Dialog,'Style','pushbutton','String',{'Done setting parameters.'},'Position',[dborder dborder cwidth 2*cheight],'Callback',@bot.buttonQuitPushed);
            
            uiwait(msgbox({'Draw a rectangle around a spot', 'to estimate sigma of fitting gaussian.'},'Hint','modal'));
            
            uiwait(bot.Dialog)
        end
        
        function buttonQuitPushed(bot,src,callbackdata)
            strings = cell(1,size(bot.Prmts,1)+1);
            strings{1} = sprintf('chan. | use | sigma | thres.');
            for i = 1:size(bot.Prmts,1)
                if bot.Prmts(i,2) == 1
                    b = 'yes';
                else
                    b = 'no';
                end 
                strings{i+1} = sprintf('%d | %s | %.02f | %.02f',bot.Prmts(i,1),b,bot.Prmts(i,3),bot.Prmts(i,4));
            end
            ButtonName = questdlg(strings,'Double check...', 'Ok', 'Redo', 'Ok');
            if strcmp(ButtonName,'Ok')
                delete(bot.Figure);
                delete(bot.Dialog);
            end
        end
        
        function editThr(bot,src,callbckdata)
            n = str2double(src.String);
            if isnan(n)
                errordlg('Threshold should be a number.', 'Oops');
            elseif n <= 0
                errordlg('Threshold should be > 0.', 'Oops');
            else
                bot.SDThr = n;
                bot.ThrText.String = sprintf('alpha: %f', bot.SDThr);
                bot.Prmts(bot.ChannelIndex,4) = bot.SDThr;
            end
        end
        
        function editSigma(bot,src,callbackdata)
            n = str2double(src.String);
            if isnan(n)
                errordlg('Sigma should be a number.', 'Oops');
            elseif n < 1
                errordlg('Sigma should be >= 1.', 'Oops');
            else
                bot.SDSigma = n;
                bot.SigmaText.String = sprintf('sigma: %.02f', bot.SDSigma);
                bot.Prmts(bot.ChannelIndex,3) = bot.SDSigma;
            end
        end
        
        function checkboxUseChannelClicked(bot,src,callbackdata)
            bot.Prmts(bot.ChannelIndex,2) = src.Value;
        end
        
        function checkboxOverlayClicked(bot,src,callbackdata)
            if ~isempty(bot.SpotsCoord)
                if src.Value == 1
                    set(bot.SpotsHandle,'XData',bot.SpotsCoord(:,1),'YData',bot.SpotsCoord(:,2));
                else
                    set(bot.SpotsHandle,'XData',[],'YData',[]);
                end
            end
        end
        
        function buttonDetectSpotsPushed(bot,src,callbackdata)
            bot.Spots = advPointSourceDetection(bot.Image, bot.SDSigma, true, 'Alpha', bot.SDThr) > 0;
            position = bot.Figure.Position;
            position(1) = position(1)+50;
            position(2) = position(2)-50;
            fg = figure('Position',position,'NumberTitle','off','Name','Spots');
            bot.Bxis = axes('Parent',fg,'Position',[0 0 1 1]);
            imshow(bot.Spots), hold on
            [y,x] = find(bot.Spots);
            bot.SpotsCoord = [x y];
            plot(x,y,'o'), hold off
            linkaxes([bot.Axis, bot.Bxis],'xy')
            bot.CheckboxOverlay.Value = 0;
            set(bot.SpotsHandle,'XData',[],'YData',[]);
        end
        
        function popupManage(bot,src,callbackdata)
            bot.ChannelIndex = src.Value;
            bot.Image = bot.Stack(:,:,bot.Channels(bot.ChannelIndex));
            bot.ImageHandle.CData = bot.Image;
            bot.Figure.Name = sprintf('Channel %d', bot.Channels(bot.ChannelIndex));
            bot.LowerThreshold = 0;
            bot.UpperThreshold = 1;
            bot.LowerThresholdSlider.Value = 0;
            bot.UpperThresholdSlider.Value = 1;
            bot.CheckboxOverlay.Value = 0;
            set(bot.SpotsHandle,'XData',[],'YData',[]);
            bot.SpotsCoord = [];
            
            bot.SDThr = bot.Prmts(bot.ChannelIndex,4);
            bot.SDSigma = bot.Prmts(bot.ChannelIndex,3);
            bot.ThrText.String = sprintf('alpha: %f', bot.SDThr);
            bot.ThrEdit.String = sprintf('%.02f', bot.SDThr);
            bot.SigmaText.String = sprintf('sigma: %.02f', bot.SDSigma);
            bot.SigmaEdit.String = sprintf('%.02f', bot.SDSigma);
            bot.CheckboxUseChannel.Value = bot.Prmts(bot.ChannelIndex,2);
        end
        
        function continuousSliderManage(bot,src,callbackdata)
            tag = callbackdata.AffectedObject.Tag;
            value = callbackdata.AffectedObject.Value;
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
            bot.ImageHandle.CData = I;
        end
        
        function closeDialog(bot,src,callbackdata)
            delete(bot.Figure);
            delete(bot.Dialog);
        end
        
        function closeFigure(bot,src,callbackdata)
            delete(bot.Figure);
            delete(bot.Dialog);
        end
        
        function mouseMove(bot,src,callbackdata)
            if bot.MouseIsDown
                p = bot.Axis.CurrentPoint;
                col = round(p(1,1));
                row = round(p(1,2));

                if row > 0 && row <= size(bot.Image,1) && col > 0 && col <= size(bot.Image,2)
                    row0 = bot.p0(1);
                    col0 = bot.p0(2);

                    rowA = min(row0,row);
                    rowB = max(row0,row);
                    colA = min(col0,col);
                    colB = max(col0,col);

                    set(bot.BoxHandle,'XData',[colA colB colB colA colA],'YData',[rowA rowA rowB rowB rowA]);
                else
                    bot.MouseIsDown = false;
                    bot.p0 = [];
                    bot.p1 = [];
                end
            end
        end
        
        function mouseDown(bot,src,callbackdata)
            p = bot.Axis.CurrentPoint;
            col = round(p(1,1));
            row = round(p(1,2));
            if row > 0 && row <= size(bot.Image,1) && col > 0 && col <= size(bot.Image,2)
                bot.p0 = [row; col];
                bot.MouseIsDown = true;
            end
        end
        
        function mouseUp(bot,src,callbackdata)
            p = bot.Axis.CurrentPoint;
            col = round(p(1,1));
            row = round(p(1,2));
            if row > 0 && row <= size(bot.Image,1) && col > 0 && col <= size(bot.Image,2)
                bot.p1 = [row; col];
                bot.MouseIsDown = false;
                
                set(bot.BoxHandle,'XData',[],'YData',[]);
                
                bot.fitGauss2D();
            end
            bot.p0 = [];
            bot.p1 = [];
        end
        
        function fitGauss2D(bot)
            if ~isempty(bot.p0) && ~isempty(bot.p1)
                pA = bot.p0; pB = bot.p1;
                rowA = min(pA(1),pB(1));
                rowB = max(pA(1),pB(1));
                colA = min(pA(2),pB(2));
                colB = max(pA(2),pB(2));
                BI = bot.Image(rowA:rowB,colA:colB);
                [y,x] = meshgrid(1:size(BI,2),1:size(BI,1));
                [fitresult, zfit, fiterr, zerr, resnorm, rr] = fmgaussfit(x,y,BI);
                evalFit(x,y,BI,zfit,fitresult)
            end
        end
    end
    
    methods (Static)
        function Mask = Headless(I, sigma, sdThr)
            Mask = advPointSourceDetection(I, sigma, false, 'Alpha', sdThr) > 0;
        end
    end
end
