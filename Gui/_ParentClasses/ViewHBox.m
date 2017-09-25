classdef ViewHBox < GuiComponent
    %VIEWHBOX Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = ViewHBox(parent, controller, padding, spacing)
            if ~exist('padding', 'var')
                padding = 0;
            end
            if ~exist('spacing', 'var')
                spacing = 5;
            end
            
            obj@GuiComponent(parent, controller);
            obj.component = uix.HBox('Parent', parent.component, 'Padding', padding, 'Spacing', spacing);
        end
        
        function out = setWidths(obj, widths)
            set(obj.component, 'Widths', widths);
        end
    end
    
end