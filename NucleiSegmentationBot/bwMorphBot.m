classdef bwMorphBot < handle
    properties
       Dialog
       Text
       Input
       Output
       Amount
       MorphOpIndex
       BWMorphOp
    end
    
    methods
        function bot = bwMorphBot(I)
            bot.Input = I;

            dwidth = 200;
            dborder = 10;
            cwidth = dwidth-2*dborder;
            cheight = 20;
            
            bot.Dialog = dialog('WindowStyle', 'normal',...
                                'Name', 'Grow/Shrink',...
                                'CloseRequestFcn', @bot.closeDialog,...
                                'Position',[100 100 dwidth 6*dborder+6*cheight]);

            uicontrol('Parent',bot.Dialog,'Style','pushbutton','String','Save and close','Position',[dborder 5*dborder+4*cheight cwidth 2*cheight],'Callback',@bot.buttonClosePushed);
                            
            bot.MorphOpIndex = 1;
            bot.BWMorphOp = 'thicken';
            labels = {'Grow','Shrink'};
            uicontrol('Parent',bot.Dialog,'Style','popupmenu','String',labels,'Position', [dborder 3*dborder+3*cheight cwidth cheight],'Callback',@bot.popupManage);
                            
            bot.Amount = 0;
            bot.Text = uicontrol('Parent',bot.Dialog,'Style','text','String',sprintf('%d pixels',bot.Amount),'Position',[dborder 3*dborder+2*cheight-10 cwidth cheight],'HorizontalAlignment','left');
            Slider = uicontrol('Parent',bot.Dialog,'Style','slider','Min',0,'Max',100,'Value',bot.Amount,'Position',[dborder 2*dborder+cheight cwidth cheight]);
            addlistener(Slider,'Value','PostSet', @bot.continuousSliderManage);
            
            uicontrol('Parent',bot.Dialog,'Style','pushbutton','String','Compute','Position',[dborder dborder cwidth cheight],'Callback',@bot.buttonComputePushed);

            uiwait(bot.Dialog)
        end
        
        function continuousSliderManage(bot,src,callbackdata)
            bot.Amount = round(callbackdata.AffectedObject.Value);
            bot.Text.String = sprintf('%d pixels',bot.Amount);
        end
        
        function popupManage(bot,src,callbackdata)
            bot.MorphOpIndex = src.Value;
        end
        
        function closeDialog(bot,src,callbackdata)
            delete(bot.Dialog);
        end
        
        function buttonComputePushed(bot,src,callbackdata)
            if bot.Amount ~= 0
                if bot.MorphOpIndex == 1
                    bot.BWMorphOp = 'thicken';
                    bot.Output = bwmorph(bot.Input,'thicken',bot.Amount);
                    I = double(bot.Output);
                    I(bot.Input) = 0.5;
                    f = figure('NumberTitle','off','Name','Mask Thicken');
                    axes('Parent',f,'Position',[0 0 1 1]);
                    imshow(I)
                elseif bot.MorphOpIndex == 2
                    bot.BWMorphOp = 'erode';
                    bot.Output = bwmorph(bot.Input,'erode',bot.Amount);
                    I = 0.5*double(bot.Input);
                    I(bot.Output) = 1;
                    f = figure('NumberTitle','off','Name','Mask Thin');
                    axes('Parent',f,'Position',[0 0 1 1]);
                    imshow(I)
                end
            else
                bot.Output = bot.Input;
                f = figure('NumberTitle','off','Name','Output == Input');
                axes('Parent',f,'Position',[0 0 1 1]);
                imshow(bot.Output)
            end
            
        end
        
        function buttonClosePushed(bot,src,callbackdata)
            delete(bot.Dialog);
        end
    end
    
    methods (Static)
        function Mask = Headless(BW,bwMorphOp,amount)
            Mask = bwmorph(BW,bwMorphOp,amount);
        end
    end
end