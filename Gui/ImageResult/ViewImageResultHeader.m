classdef ViewImageResultHeader < ViewHBox & EventListener
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
            obj@EventListener;
            
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
        
        function updateAxes(obj)
            cellfun(@(v) v.update, obj.views);
        end
    end
    
    %% overridden from EventListener
    methods
        % When events happen, this function jumps.
        % event is the event sent from the EventSender
        function onEvent(obj, event)
            if isfield(event.extraInfo, ImageScanResult.EVENT_IMAGE_UPDATED)
                obj.updateAxes;
            end
        end
    end
    
end