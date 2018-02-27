classdef SwitchPgControlled < EventSender & EventListener
    %SWITCHPSCONTROLLED Switch, controlled by a pulse generator (PG)
    %   A PG is either a pulse blaster or a pulse streamer, and they both
    %   have the same interface.
    
    % Maybe hould be subclass of class "Switch"
    
    properties
        isEnabled   % logical
        
        channel     % string
    end
    
    properties(Constant = true, Hidden = true)
        NEEDED_FIELDS = {'switchChannelName'}
        OPTOINAL_FIELDS = {'isEnabled'}
    end
    
    methods
        function obj = SwitchPgControlled(name, pgChannel)
            % name - the nickname of the object
            % pgChannel - vector of chars. the channel that PS will work with
            PG = getObjByName(PulseGenerator.NAME);
            obj@EventSender(name);
            obj@EventListener(PG.NAME);
            BaseObject.addObject(obj);  % so it can be reached by BaseObject.getByName()
            
%             pg.addNewChannel(name, pgChannel);     in the meanwhile, this is not needed
            obj.channel = pgChannel;
            obj.isEnabled = false;
        end
        
        function set.isEnabled(obj, newValue)
            % newValue - logical (i.e. true \ false \ 1 \ 0)
            if (isnumeric(newValue) && (newValue == 0 || newValue == 1)) ...
                    || islogical(newValue)
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
                error('Can''t set "isEnabled" to something other than (true \ false \ 1 \ 0). aborting');
            end
        end
    end
    
    %% Overridden from EventListener
    methods
        % event is the event sent from the EventSender
        function onEvent(obj, event)
            PG = event.sender;
            newEnabled = PG.isOn(obj.name);
            if newEnabled ~= obj.isEnabled
                obj.isEnabled = newEnabled;
                obj.sendEvent(struct('isEnabled', newEnabled));
            end
        end
    end
    
end

