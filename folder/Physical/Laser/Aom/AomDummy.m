classdef AomDummy < LaserPartAbstract
    %LASERDUMMY dummy laser in which everything works
    
    methods
        % constructor
        function obj = AomDummy(name)
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
        function out = setEnabledRealWorld(obj, ignored) %#ok<*INUSD,*MANU>
            out = true;
        end
        
        function out = setValueRealWorld(obj, ignored)
            out = true;
        end
    end
    
end