classdef switchBetweenImagesTool < handle
    properties
        Figure
        Axis
        Handle
        Image
        ShowingFirstImage
    end
    
    methods
        function tool = switchBetweenImagesTool(Image1,Image2)
% switchBetweenImagesTool(Image1,Image2)
%
% switches betwen Image1 and Image2 at the pressing of the Space key;
% works best for images of the same size

            tool.Image{1} = Image1;
            tool.Image{2} = Image2;
            
            tool.Figure = figure('NumberTitle','off', 'Name','Image 1 (press Space to switch, Esc to quit)',...
                                 'CloseRequestFcn',@tool.closeTool,'Resize','on', 'KeyPressFcn',@tool.keyPressed);
            
            tool.Axis = axes('Parent',tool.Figure,'Position',[0 0 1 1]);
            tool.Handle = imshow(tool.Image{1});
            tool.ShowingFirstImage = true;
        end
        
        function keyPressed(tool,~,event)
            if strcmp(event.Key,'space')
                if tool.ShowingFirstImage
                    tool.Handle.CData = tool.Image{2};
                    tool.ShowingFirstImage = false;
                    tool.Figure.Name = 'Image 2 (press Space to switch, Esc to quit)';
                else
                    tool.Handle.CData = tool.Image{1};
                    tool.ShowingFirstImage = true;
                    tool.Figure.Name = 'Image 1 (press Space to switch, Esc to quit)';
                end
            elseif strcmp(event.Key,'escape')
                tool.closeTool(tool);
            end
        end
        
        function closeTool(tool,~,~)
            delete(tool.Figure);
        end
        
    end
    
end
