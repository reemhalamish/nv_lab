classdef LaserSourceDummy < LaserPartAbstract
    %LASERSOURCEDUMMY dummy laser in which everything works
    
    properties
        canSetEnabled = true;
        canSetValue = true;  
    end
    
    properties (Hidden)
        dummyValue = 0;
        dummyEnabled = false;
    end
    
    methods
        % constructor
        function obj = LaserSourceDummy(name)
            obj@LaserPartAbstract(name);
            obj.initLaserPart();
        end
    end
    
    %% Overridden from LaserPartAbstract
    %% These functions call physical objects. Tread with caution!
    methods (Access = protected)
        function setValueRealWorld(obj, newValue)
            % Sets the voltage value in physical laser part
            obj.dummyValue = newValue;
        end
        
        function setEnabledRealWorld(obj, newBool)
            % Sets the physical laser part on (true) or off (false)
            obj.dummyEnabled = newBool;
        end

        function value = getValueRealWorld(obj)
            % Gets the voltage value from physical laser part
            value = obj.dummyValue;
        end
        
        function tf = getEnabledRealWorld(obj)
            % Returns whether the physical laser part is on (true) or off (false)
            tf = obj.dummyEnabled;
        end
    end
end

