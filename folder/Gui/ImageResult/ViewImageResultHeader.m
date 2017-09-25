classdef ViewImageResultHeader < ViewHBox
    %VIEWSTAGESCANHEADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        vPlotOptions
        vColorMap
        vCursor
        views   % all the 3
    end
    
    methods
        function obj = ViewImageResultHeader(parent, controller)
            panel = ViewExpandablePanel(parent, controller, 'Image Options');
            padding = 5;
            spacing = 10;
            obj@ViewHBox(panel, controller, padding, spacing);
            
            obj.vPlotOptions = ViewImageResultPanelPlot(obj,controller);
            obj.vColorMap = ViewImageResultPanelColormap(obj,controller);
            obj.vCursor = ViewImageResultPanelCursor(obj,controller);
            
            obj.views = {obj.vPlotOptions, obj.vColorMap, obj.vCursor};
            widths = cellfun(@(v) v.width, obj.views);
            heights = cellfun(@(v) v.height, obj.views);
            
            obj.setWidths(-widths); % minus to take all the space
            obj.width = sum(widths) + 15 + 5*length(widths);
            obj.height = max(heights) + 10;
        end
        
        function updateAxes(obj, axesFigure)
            for cvCell = obj.views
                childView = cvCell{:};
                todo = 'let the children do whatever with the axes';
            end
        end
    end
    
end