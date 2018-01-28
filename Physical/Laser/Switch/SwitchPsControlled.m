classdef SwitchPsControlled < EventSender & EventListener
    %SWITCHPSCONTROLLED Summary of this class goes here
    %   Detailed explanation goes here
    
    % Should be subclass of class "Switch" - to be implemented later
    
    properties
        isEnabled
    end
    
    properties(Constant = true, Hidden = true)
        STRUCT_NEEDED_FIELDS = {'switchChannel'}
        STRUCT_OPTOINAL_FIELDS = {'isEnabled'}
    end
    
    methods
        function obj = SwitchPsControlled(name, psChannel)
            % name - the nickname of the object
            % psChannel - integer, the channel that PS will work with
            ps = getObjByName(PulseStreamer.NAME);
            obj@EventSender(name);
            obj@EventListener(ps.name);
            BaseObject.addObject(obj);  % so it can be reached by BaseObject.getByName()
            
            ps.addNewChannel(name, psChannel);
            obj.isEnabled = false;
        end
        
        function set.isEnabled(obj, newValue)
            % newValue - logical (i.e. true \ false \ 1 \ 0)
            if ((isnumeric(newValue) && (newValue == 0 || newValue == 1)) ...
                    || islogical(newValue))
                obj.isEnabled = newValue;
                ps = getObjByName(PulseStreamerClass.NAME);
                ps.switchOnly(obj.name, newValue);
                obj.sendEvent(struct('isEnabled', newValue));
                % ^ let everyone know about the success! :)
            else
                error('Can''t set "isEnabled" to something other than (true \ false \ 1 \ 0). aborting');
            end
        end
    end
    
    methods(Static)
        function psControlled = createFromStruct(laserName, struct)
            missingField = FactoryHelper.usualChecks(struct, SwitchPsControlled.STRUCT_NEEDED_FIELDS);
            if ~isnan(missingField)
                errorMsg = 'Error while creating a PsControlled object (name: "%s"), missing field! (field missing: "%s")';
                error(errorMsg, laserName, missingField);
            end
            
            name = sprintf('%s fast switch', laserName);
            psControlled = SwitchPsControlled(name, struct.switchChannel);
            
            % check for optional field "isEnabled" and set it correctly
            if isnan(FactoryHelper.usualChecks(struct, SwitchPsControlled.STRUCT_OPTOINAL_FIELDS))
                % usualChecks() returning nan means everything ok
                psControlled.isEnabled = struct.isEnabled;
            end
        end
    end
    
    %% Overridden from EventListener
    methods
        % event is the event sent from the EventSender
        function onEvent(obj, event)
            ps = getObjByName(PulseStreamerClass.NAME);
            newEnabled = ps.isOn(obj.name);
            if newEnabled ~= obj.isEnabled
                obj.isEnabled = newEnabled;
                obj.sendEvent(struct('isEnabled', newEnabled));
            end
        end
    end
    
end

