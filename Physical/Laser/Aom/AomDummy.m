classdef AomDummy < LaserPartAbstract
    %AOMDUMMY dummy aom in which everything works
    
    properties
        canSetValue = true;
        canSetEnabled = true;
    end
    
    properties (Access = private)
        valuePrivate
        enabledPrivate
    end
    
    methods
        % constructor
        function obj = AomDummy(name)
            obj@LaserPartAbstract(name);
            obj.initLaserPart();
        end
    end
    
    methods
        function val = getValueRealWorld(obj)
            % Gets the voltage value from physical laser part
            val = obj.valuePrivate;
        end
        
        function tf = getEnabledRealWorld(obj)
            % Returns whether the physical laser part is on (true) or off (false)
            tf = obj.enabledPrivate;
        end
    end
    
    methods(Access = protected)
        function setEnabledRealWorld(obj, tf) %#ok<*INUSD,*MANU>
            obj.enabledPrivate = tf;
        end
        
        function setValueRealWorld(obj, val)
            obj.valuePrivate = val;
        end
    end
    
end