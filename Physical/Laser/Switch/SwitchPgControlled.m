classdef SwitchPgControlled < EventSender & EventListener
    %SWITCHPSCONTROLLED Switch, controlled by a pulse generator (PG)
    %   A PG is either a pulse blaster or a pulse streamer, and they both
    %   have the same interface.
    
    % Maybe hould be subclass of class "Switch"
    
    properties
        isEnabled   % logical
        
        channel     % string
    end
    
    properties (Constant, Hidden)
        NEEDED_FIELDS = {'switchChannelName'}
        OPTIONAL_FIELDS = {'isEnabled'}
    end
    
    methods
        function obj = SwitchPgControlled(name, pgChannel)
            % name - the nickname of the object
            % pgChannel - 'Channel. PG will work with *this*.'
            PG = getObjByName(PulseGenerator.NAME);
            obj@EventSender(name);
            obj@EventListener(PG.NAME);
            BaseObject.addObject(obj);  % so it can be reached by BaseObject.getByName()
            
            obj.channel = pgChannel;
            % When new PG is implemented:
            assert(pgChannel.isDigital, 'Switch channels must be of type Digital!');
            PG.registerChannel(pgChannel);
            obj.channel = pgChannel.name;
            obj.isEnabled = false;
        end
        
        function set.isEnabled(obj, newValue)
            % newValue - logical (i.e. true \ false \ 1 \ 0)
            if ValidationHelper.isTrueOrFalse(newValue)
                newValue = logical(newValue);
                obj.isEnabled = newValue;
                PG = getObjByName(PulseGenerator.NAME);
                if newValue
                    PG.on(obj.channel); %#ok<MCSUP>
                else
                    PG.off;
                end
                obj.sendEvent(struct('isEnabled', newValue));
                % ^ let everyone know about the success! :)
            else
                EventStation.anonymousError('Can''t set "isEnabled" to anything other than (true \ false \ 1 \ 0). Aborting');
            end
        end
    end
    
    %% Overridden from EventListener
    methods
        % event is the event sent from the EventSender
        function onEvent(obj, event)
            PG = event.creator;
            newEnabled = PG.isOn(obj.name);
            if newEnabled ~= obj.isEnabled
                obj.isEnabled = newEnabled;
                obj.sendEvent(struct('isEnabled', newEnabled));
            end
        end
    end
    
end

