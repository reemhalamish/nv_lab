classdef ViewImageResultHeader < ViewHBox
    %VIEWSTAGESCANHEADER the header for the ImageResults view
    %   consists of 3 panels.
    
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
            % maybe replace loop with cellfun
            for cvCell = obj.views
                childView = cvCell{:};
                childView.update;
            end
        end
    end
    
end