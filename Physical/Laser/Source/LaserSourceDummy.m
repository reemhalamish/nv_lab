classdef LaserSourceDummy < LaserPartAbstract
    %LASERSOURCEDUMMY dummy laser in which everything works
    
    methods
        % constructor
        function obj = LaserSourceDummy(name)
            obj@LaserPartAbstract(name);
            obj.initLaserPart();
        end
        
        function out = canSetValue(obj)
            out = true;
        end
        
        function out = canSetEnabled(obj)
            out = true;
        end
    end
    
    methods(Access = protected)
        function out = setEnabledRealWorld(obj, newBoolValue) %#ok<*INUSD,*MANU>
            out = true;
        end
        
        function out = setValueRealWorld(obj, newValue)
            out = true;
        end
    end
    
end

