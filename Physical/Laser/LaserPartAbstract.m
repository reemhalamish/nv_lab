classdef (Abstract) LaserPartAbstract < EventSender
    %LASERABSTRACT Abstract layer above the physics. 
    %   saves all the matlab info (such as current value, is active) and
    %   calls events.
    %
    %   child classes duty:
    %   @ implement method canSetEnabled()
    %   @ implement method canSetValue()
    %   @ implement method setEnabledRealWorld()
    %   @ implement method setValueRealWorld()
    %   @ call method initLaserPart() after calling all the inheritance constructors
    
    
    %% those properties are private, because child classes don't need to 
    %  know such properties even exist.
    properties(SetAccess = private, GetAccess = public)
        currentValue
        isEnabled
    end

    properties(Constant = true)
        MIN_VALUE = 0;
        MAX_VALUE = 100;
    end
    
    methods
        %% constructor
        function obj = LaserPartAbstract(name)
            obj@EventSender(name);
            addBaseObject(obj);  % so it can be reached by BaseObject.getByName()
        end
        function initLaserPart(obj)
            if obj.canSetEnabled()
                obj.setEnabled(false);
            else
                obj.isEnabled = true;
            end
            
            if obj.canSetValue()
                obj.setNewValue(0);
            else
                obj.currentValue = 0;
            end
        end
        
        %% set a new value to the laser
        function bool = setNewValue(obj, newValue)
            if ValidationHelper.isInBorders(newValue, LaserPartAbstract.MIN_VALUE, LaserPartAbstract.MAX_VALUE)
                bool = obj.setValueRealWorld(newValue);
                if (bool)
                    obj.currentValue = newValue;
                    obj.sendEvent(struct('currentValue', newValue));
                else
                    obj.sendErrorRealWorld();
                end
            else
                error_msg = 'request to set power to %d: off limits! ignoring. (limits: [%d, %d])';
                limit_min = LaserPartAbstract.MIN_VALUE;
                limit_max = LaserPartAbstract.MAX_VALUE;
                obj.sendWarning(sprintf(error_msg, newValue, limit_min, limit_max));
                bool = false;
            end
        end
        
        %% setting the "enabled" state of the laser
        function bool = setEnabled(obj, newValueBool)
            if (obj.setEnabledRealWorld(newValueBool))
                obj.isEnabled = newValueBool;
                obj.sendEvent(struct('isEnabled', newValueBool));
                bool = true;
            else
                obj.sendErrorRealWorld()
                bool = false;
            end
        end
        
    end
    
    
    methods(Abstract = true)
        %% calling the real world to set the voltage value
        canSetValue(obj) % returns boolean - can you set values
        canSetEnabled(obj) % returns boolean - can you set the "enabled" boolean state
    end
    
    methods(Abstract = true, Access = protected)
        %% calling the real world to set the voltage value
        setValueRealWorld(obj, newValue) % returns boolean success
            % this function does actual calling to the real world!
            % child class will need to override THIS method
            
        %% calling the real world to set the "enbled" value
        %% return boolean - to indicate if the action went well
        setEnabledRealWorld(obj, newValueBoolean)
            % this function does actual calling to the real world!
            % child class will need to override THIS method
    end
    
end

