classdef ViewSpcmInImage < GuiComponent
    %VIEWSPCMINIMAGE wrapper for ViewSpcm for display in main image view
    
    properties (Constant = true)
        VIEW_HEIGHT = 100;
        VIEW_WIDTH = -1;
    end
    
    methods
        function obj = ViewSpcmInImage(parent,controller)
            panel = ViewExpandablePanel(parent, controller, 'SPCM Counter');
            obj@GuiComponent(parent,controller);
            spcmView = ViewSpcm(panel,controller,obj.VIEW_HEIGHT,obj.VIEW_WIDTH);
            obj.component = spcmView.component;
        end
    end
    
end

