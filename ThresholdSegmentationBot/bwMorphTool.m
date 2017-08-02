classdef bwMorphTool < handle
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
        function tool = bwMorphTool(I)
            tool.Input = I;

            dwidth = 200;
            dborder = 10;
            cwidth = dwidth-2*dborder;
            cheight = 20;
            
            tool.Dialog = dialog('WindowStyle', 'normal',...
                                'Name', 'Grow/Shrink',...
                                'CloseRequestFcn', @tool.closeDialog,...
                                'Position',[100 100 dwidth 6*dborder+6*cheight]);

            uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','Save and close','Position',[dborder 5*dborder+4*cheight cwidth 2*cheight],'Callback',@tool.buttonClosePushed);
                            
            tool.MorphOpIndex = 1;
            tool.BWMorphOp = 'thicken';
            labels = {'Grow','Shrink'};
            uicontrol('Parent',tool.Dialog,'Style','popupmenu','String',labels,'Position', [dborder 3*dborder+3*cheight cwidth cheight],'Callback',@tool.popupManage);
                            
            tool.Amount = 0;
            tool.Text = uicontrol('Parent',tool.Dialog,'Style','text','String',sprintf('%d pixels',tool.Amount),'Position',[dborder 3*dborder+2*cheight-10 cwidth cheight],'HorizontalAlignment','left');
            Slider = uicontrol('Parent',tool.Dialog,'Style','slider','Min',0,'Max',100,'Value',tool.Amount,'Position',[dborder 2*dborder+cheight cwidth cheight]);
            addlistener(Slider,'Value','PostSet', @tool.continuousSliderManage);
            
            uicontrol('Parent',tool.Dialog,'Style','pushbutton','String','Compute','Position',[dborder dborder cwidth cheight],'Callback',@tool.buttonComputePushed);

            uiwait(tool.Dialog)
        end
        
        function continuousSliderManage(tool,src,callbackdata)
            tool.Amount = round(callbackdata.AffectedObject.Value);
            tool.Text.String = sprintf('%d pixels',tool.Amount);
        end
        
        function popupManage(tool,src,callbackdata)
            tool.MorphOpIndex = src.Value;
        end
        
        function closeDialog(tool,src,callbackdata)
            delete(tool.Dialog);
        end
        
        function buttonComputePushed(tool,src,callbackdata)
            if tool.Amount ~= 0
                if tool.MorphOpIndex == 1
                    tool.BWMorphOp = 'thicken';
                    tool.Output = bwmorph(tool.Input,'thicken',tool.Amount);
                    I = double(tool.Output);
                    I(tool.Input) = 0.5;
                    f = figure('NumberTitle','off','Name','Mask Thicken');
                    axes('Parent',f,'Position',[0 0 1 1]);
                    imshow(I)
                elseif tool.MorphOpIndex == 2
                    tool.BWMorphOp = 'erode';
                    tool.Output = bwmorph(tool.Input,'erode',tool.Amount);
                    I = 0.5*double(tool.Input);
                    I(tool.Output) = 1;
                    f = figure('NumberTitle','off','Name','Mask Thin');
                    axes('Parent',f,'Position',[0 0 1 1]);
                    imshow(I)
                end
            else
                tool.Output = tool.Input;
                f = figure('NumberTitle','off','Name','Output == Input');
                axes('Parent',f,'Position',[0 0 1 1]);
                imshow(tool.Output)
            end
            
        end
        
        function buttonClosePushed(tool,src,callbackdata)
            delete(tool.Dialog);
        end
    end
    
    methods (Static)
        function Mask = Headless(BW,bwMorphOp,amount)
            Mask = bwmorph(BW,bwMorphOp,amount);
        end
    end
end