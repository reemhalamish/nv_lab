classdef SwitchPbControlled < EventSender & EventListener
    %SWITCHPBCONTROLLED Summary of this class goes here
    %   Detailed explanation goes here
    
    % Should be subclass of class "Switch" - to be implemented later
    
    properties
        isEnabled
    end
    
    properties (Constant, Hidden)
        STRUCT_NEEDED_FIELDS = {'switchChannel'}
        STRUCT_OPTOINAL_FIELDS = {'isEnabled'}
    end
    
    methods
        function obj = SwitchPbControlled(name, pbChannel)
            % name - the nickname of the object
            % pbChannel - integer, the channel that PB will work with
            pb = getObjByName(PulseBlaster.NAME);
            obj@EventSender(name);
            obj@EventListener(pb.name);
            
            pb.addNewChannel(name, pbChannel);
            obj.isEnabled = false;
        end
        
        function set.isEnabled(obj, newValue)
            % newValue - logical (i.e. true \ false \ 1 \ 0)
            if ((isnumeric(newValue) && (newValue == 0 || newValue == 1)) ...
                    || islogical(newValue))
                obj.isEnabled = newValue;
                pb = getObjByName(PulseBlaster.NAME);
                pb.switchOnly(obj.name, newValue);
                obj.sendEvent(struct('isEnabled', newValue));
                % ^ let everyone know about the success! :)
            else
                error('Can''t set "isEnabled" to something other than (true \ false \ 1 \ 0). aborting');
            end
        end
    end
    
    methods (Static)
        function pbControlled = createFromStruct(laserName, struct)
            missingField = FactoryHelper.usualChecks(struct, SwitchPbControlled.STRUCT_NEEDED_FIELDS);
            if ~isnan(missingField)
                errorMsg = 'Error while creating a PbControlled object (name: "%s"), missing field! (field missing: "%s")';
                error(errorMsg, laserName, missingField);
            end
            
            name = sprintf('%s fast switch', laserName);
            pbControlled = SwitchPbControlled(name, struct.switchChannel);
            
            % check for optional field "isEnabled" and set it correctly
            if isnan(FactoryHelper.usualChecks(struct, SwitchPbControlled.STRUCT_OPTOINAL_FIELDS))
                % usualChecks() returning nan means everything ok
                pbControlled.isEnabled = struct.isEnabled;
            end
        end
    end
    
    %% Overridden from EventListener
    methods
        % event is the event sent from the EventSender
        function onEvent(obj, event)
            pb = getObjByName(PulseBlaster.NAME);
            newEnabled = pb.isOn(obj.name);
            if newEnabled ~= obj.isEnabled
                obj.isEnabled = newEnabled;
                obj.sendEvent(struct('isEnabled', newEnabled));
            end
        end
    end
    
end

