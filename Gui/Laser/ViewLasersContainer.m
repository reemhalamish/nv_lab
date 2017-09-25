classdef ViewLasersContainer < ViewVBox
    % ViewLasersContainer is a container for laser views
    %   for each laser physics in the setup, create a GUI component called
    %   "LaserView" to handle that laser.
    
    properties
    end
    
    methods
        % constructor
        function obj = ViewLasersContainer(parent, controller)
            obj@ViewVBox(parent, controller);
            
            lasers = LaserGate.getLasers();
            heights = [];
            
            for i = 1 : length(lasers)
                laserGate = lasers{i};
                viewLaser = ViewLaser(obj, controller, laserGate);
                obj.width = viewLaser.width;
                heights(i) = viewLaser.height; %#ok<AGROW>
            end
            set(obj.component, 'Heights', heights);
            set(obj.component, 'Spacing', 5);
            
            obj.height = sum(heights) + length(heights) * 3;
        end
    end 
end