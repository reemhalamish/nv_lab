classdef (Abstract) LaserPartAbstract < EventSender
    %LASERABSTRACT Abstract layer above the physics. 
    %   Saves all the matlab info (such as current value, isActive) and
    %   calls events.
    %
    %   Child classes must:
    %   @ assign value to property canSetEnabled
    %   @ assign value to property canSetValue
    %   @ call method initLaserPart() after calling all the inheritance constructors
    %
    %   If needed, Child class should override:
    %     
    %     %% Overridden from LaserPartAbstract
    %         %% These functions call physical objects. Tread with caution!
    %         methods (Access = protected)
    %             function setValueRealWorld(obj, newValue)
    %                 % Sets the voltage value in physical laser part
    %             end
    %             
    %             function setEnabledRealWorld(obj, newBool)
    %                 % Sets the physical laser part on (true) or off (false)
    %             end
    %         end
    %             
    %         methods
    %             function value = getValueRealWorld(obj)
    %                 % Gets the voltage value from physical laser part
    %                 value = 100;
    %             end
    %             
    %             function tf = getEnabledRealWorld(obj)
    %                 % Returns whether the physical laser part is on (true) or off (false)
    %                 tf = true;
    %             end
    %         end

    
    properties (Abstract)
        canSetEnabled   % logical
        canSetValue     % logical
    end
    
    properties (Dependent)
        value           % double. If it cannot be changed, it is effectively on full power.
        isEnabled       % logical. If it cannot be changed, it is always on.
    end
    
    properties (SetAccess = protected, Hidden)
        minValue
        maxValue
        units
    end
    
    properties (Constant)
        DEFAULT_MIN_VALUE = 0;
        DEFAULT_MAX_VALUE = 100;
        DEFAULT_UNITS = '%';
    end
    
    methods
        %% constructor
        function obj = LaserPartAbstract(name)
            obj@EventSender(name);
            addBaseObject(obj);     % so it can be reached by BaseObject.getByName()
        end
        
        function initLaserPart(obj)
            % Default initiation. Could be overridden by subclasses
            obj.isEnabled = false;
            
            obj.minValue = obj.DEFAULT_MIN_VALUE;
            obj.maxValue = obj.DEFAULT_MAX_VALUE;
            obj.units = obj.DEFAULT_UNITS;
            
            obj.value = obj.minValue;
        end
        
        function on(obj)
            obj.isEnabled = true;
        end
        
        function off(obj)
            obj.isEnabled = false;
        end
    end
       
    methods % Setters
        %% New syntax
        function set.value(obj, newValue)
            % Set a new value to the laser
            if ~isnumeric(newValue)
                newValue = str2double(newValue);
                if isnan(newValue)     % Conversion failed
                    obj.sendError('Laser power must be a number');
                end
            end
            
            if ValidationHelper.isInBorders(newValue, obj.minValue, obj.maxValue)
                try
                    obj.setValueRealWorld(newValue);
                    obj.sendEvent(struct('value', newValue));
                catch
                    obj.sendErrorRealWorld();
                end
            else
                obj.sendError(sprintf('Laser power can''t be set to %d%s: out of limits!\nIgnoring. (limits: [%d, %d])', ...
                    newValue, obj.units, obj.minValue, obj.maxValue));
            end
        end
        
        function set.isEnabled(obj, newValueLogical)
            % Setting the "enabled" state of the laser
            obj.setEnabledRealWorld(newValueLogical);
            obj.sendEvent(struct('isEnabled', newValueLogical));
        end
        
        %% Old syntax
        function bool = setNewValue(obj, newValue)
            % Set a new value to the laser
            % This is a wrapper function for set.value, which returns
            % whether it succeeded
            try
                obj.value = newValue;
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
                % we want to assert that newValueBool is logical, however
                % islogical would not work, since 0 and 1 are not logical,
                % yet they equal false and true.
                logicalValues = [true, false];      
                assert(ismember(newValueBool, logicalValues), ...
                    'Value must be either true or false! Nothing happenned.')
                obj.isEnabled = newValueBool;
                bool = true;
            catch err
                bool = false; %#ok<NASGU>
                rethrow(err);
            end
        end
        
        %% Getters
        function value = get.value(obj)
            if obj.canSetValue
                value = obj.getValueRealWorld;
            else
                value = 100;
            end
        end
        
        function tf = get.isEnabled(obj)
            if obj.canSetValue
                tf = obj.getEnabledRealWorld;
            else
                tf = true;
            end
        end
        
    end
    
        %% These functions call physical objects. Tread with caution!
        methods (Access = protected)
            function setValueRealWorld(~, ~)
                % Sets the voltage value in physical laser part
            end
            
            function setEnabledRealWorld(~, ~)
                % Sets the physical laser part on (true) or off (false)
            end
        end
            
        methods
            function value = getValueRealWorld(~)
                % Gets the voltage value from physical laser part
                value = 100;
            end
            
            function tf = getEnabledRealWorld(~)
                % Returns whether the physical laser part is on (true) or off (false)
                tf = true;
            end
        end
    
end

