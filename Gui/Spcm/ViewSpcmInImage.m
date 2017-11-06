classdef ViewSpcmInImage < GuiComponent
    %VIEWSPCMINIMAGE wrapper for ViewSpcm for display in main image view
    
    properties (Constant = true)
        VIEW_HEIGHT = 300;
        VIEW_WIDTH = 150;
    end
    
    methods
        function obj = ViewSpcmInImage(parent,controller)
            panel = ViewExpandablePanel(parent, controller, 'SPCM Counter');
            obj@GuiComponent(parent,controller);
            spcmView = ViewSpcm(panel,controller,VIEW_HEIGHT,VIEW_WIDTH);
            obj.component = spcmView.component;
        end
    end
    
end

