classdef (Abstract) LaserPartAbstract < EventSender
    %LASERABSTRACT Abstract layer above the physics. 
    %   Saves all the matlab info (such as current value, isActive) and
    %   calls events.
    %
    %   Child classes must:
    %   @ implement method canSetEnabled()
    %   @ implement method canSetValue()
    %   @ implement method setEnabledRealWorld()
    %   @ implement method setValueRealWorld()
    %   @ call method initLaserPart() after calling all the inheritance constructors
    
    properties
        % Have setters, need default values
        currentValue = 0;   % double
        isEnabled = true;   % logical
    end
    
    properties (Constant)
        MIN_VALUE = 0;
        MAX_VALUE = 100;
    end
    
    methods
        %% constructor
        function obj = LaserPartAbstract(name)
            obj@EventSender(name);
            addBaseObject(obj);     % so it can be reached by BaseObject.getByName()
        end
        function initLaserPart(obj)
            if obj.canSetEnabled()
                obj.setEnabled(false);
            end
            
            if obj.canSetValue()	% not necessary, unless you want to init using a different value
                obj.setNewValue(0);
            end
        end
    end
       
    methods % setters
        %% Old syntax
        function bool = setNewValue(obj, newValue)
            % Set a new value to the laser
            try
                obj.currentValue = newValue;
                bool = true;
            catch err
                bool = false;
                if err.message == obj.ERROR_MESSAGE_PHYSICAL    % Throw error only if it is physical
                    rethrow(err);
                else
                    warning(err);
                end
            end
        end
        
        function bool = setEnabled(obj, newValueBool)
            % Setting the "enabled" state of the laser
            try
                obj.isEnabled = newValueBool;
                bool = true;
            catch err
                bool = false; %#ok<NASGU>
                rethrow(err);
            end
        end
        
        %% New syntax
        function set.currentValue(obj, newValue)
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
                obj.error(error_msg, newValue, limit_min, limit_max);
            end
        end
        
        function set.isEnabled(obj, newValueLogical)
            % Setting the "enabled" state of the laser
            if (obj.setEnabledRealWorld(newValueLogical))
                obj.isEnabled = newValueLogical;
                obj.sendEvent(struct('isEnabled', newValueLogical));
            else
                obj.sendErrorRealWorld()
            end
        end
        
        
    end
    
    
    methods(Abstract)
        %% Calling the real world to set the voltage value
        tf = canSetValue(obj)       % logical. Can user set value (of laser power)
        tf = canSetEnabled(obj)     % logical. Can laser be enabled and disabled
    end
    
    methods(Abstract, Access = protected)
        %% Calling the real world to set the voltage value
        didSucceed = setValueRealWorld(obj, newValue) % returns logical
            % This function does actual calling to the real world!
            % Child classes need to override THIS method
            
        %% Calling the real world to set the "enbled" value
        %% return boolean - to indicate if the action went well
        setEnabledRealWorld(obj, newValueBoolean)
            % This function does actual calling to the real world!
            % Child classes need to override THIS method
    end
    
end

