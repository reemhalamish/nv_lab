classdef ViewVBox < GuiComponent
    %VIEWHBOX Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = ViewVBox(parent, controller, padding, spacing)
            if ~exist('padding', 'var')
                padding = 0;
            end
            if ~exist('spacing', 'var')
                spacing = 5;
            end
            
            obj@GuiComponent(parent, controller);
            obj.component = uix.VBox('Parent', parent.component, 'Padding', padding, 'Spacing', spacing);
        end
        
        function out = setHeights(obj, heights)
            set(obj.component, 'Heights', heights);
        end
    end
    
end