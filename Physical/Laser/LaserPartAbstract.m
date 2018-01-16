classdef (Abstract) LaserPartAbstract < EventSender
    %LASERABSTRACT Abstract layer above the physics. 
    %   Saves all the matlab info (such as current value, is active) and
    %   calls events.
    %
    %   Child classes must:
    %   @ implement method canSetEnabled()
    %   @ implement method canSetValue()
    %   @ implement method setEnabledRealWorld()
    %   @ implement method setValueRealWorld()
    %   @ call method initLaserPart() after calling all the inheritance constructors
    
    properties(SetAccess = private, GetAccess = public)
        % These properties are private, because child classes don't need to
        %  know such properties even exist.
        currentValue
        isEnabled
    end

    properties(Constant)
        MIN_VALUE = 0;
        MAX_VALUE = 100;
        
        GREEN_LASER_NAME = 'Green Laser';
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
        %%
        function bool = setNewValue(obj, newValue)
            % Set a new value to the laser
            if ValidationHelper.isInBorders(newValue, LaserPartAbstract.MIN_VALUE, LaserPartAbstract.MAX_VALUE)
                bool = obj.setValueRealWorld(newValue);
                if (bool)
                    obj.currentValue = newValue;
                    obj.sendEvent(struct('currentValue', newValue));
                else
                    obj.sendErrorRealWorld();
                end
            else
                error_msg = 'Laser power can''t be set to %d: out of limits! Ignoring. (limits: [%d, %d])';
                limit_min = LaserPartAbstract.MIN_VALUE;
                limit_max = LaserPartAbstract.MAX_VALUE;
                obj.sendWarning(sprintf(error_msg, newValue, limit_min, limit_max));
                bool = false;
            end
        end
        
        function bool = setEnabled(obj, newValueBool)
            % Setting the "enabled" state of the laser
            if (obj.setEnabledRealWorld(newValueBool))
                obj.isEnabled = newValueBool;
                obj.sendEvent(struct('isEnabled', newValueBool));
                bool = true;
            else
                bool = false;
                obj.sendErrorRealWorld()
            end
        end
        
    end
    
    
    methods(Abstract)
        %% calling the real world to set the voltage value
        tf = canSetValue(obj)       % logical. Can user set value (of laser power)
        tf = canSetEnabled(obj)     % logical. Can laser be enabled and disabled
    end
    
    methods(Abstract, Access = protected)
        %% calling the real world to set the voltage value
        didSucceed = setValueRealWorld(obj, newValue) % returns logical
            % This function does actual calling to the real world!
            % Child classes need to override THIS method
            
        %% calling the real world to set the "enbled" value
        %% return boolean - to indicate if the action went well
        setEnabledRealWorld(obj, newValueBoolean)
            % This function does actual calling to the real world!
            % Child classes need to override THIS method
    end
    
end

