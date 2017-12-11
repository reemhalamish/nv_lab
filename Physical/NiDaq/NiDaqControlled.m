classdef (Abstract) NiDaqControlled < EventListener
    %NIDAQCONTROLLED component that can be controlled by the NiDaq
    %   this class only affects 2 states:
    %       @ when the component is being created
    %       @ when the NiDaq resests
    
    
%     % un-comment those line in child classes:
%         methods
%             function onNiDaqReset(obj, niDaq)
%                 % this function jumps when the NiDaq resets
%                 % each component can decide what to do
%             end
%         end
%     
    
    properties
    end
    
    methods(Access = protected)
        function obj = NiDaqControlled(niDaqChannelName, niDaqChannel)
            % niDaqChannelName - string. the name that the daq will call this component
            % niDaqChannel - string. the channel to register to.
            % SUPPORTS CELL (NON-SCALAR) INPUT!
            obj@EventListener(NiDaq.NAME);
            niDaq = getObjByName(NiDaq.NAME);
            if iscell(niDaqChannelName) && iscell(niDaqChannel)
                if length(niDaqChannelName) ~= length(niDaqChannel)
                    EventStation.anonymousError('can''t initiate NiDaqControlled object - cell-size mismatch')
                end
                
                for i=1:length(niDaqChannelName)
                    niDaq.registerChannel(niDaqChannel{i}, niDaqChannelName{i});
                end
            else  % scalar
                niDaq.registerChannel(niDaqChannel, niDaqChannelName);
            end
        end
    end
    
    methods(Abstract)
        % The function onEvent() was divided into multiple functions, so
        % that child classes won't override onEvent. 
        % This way, we can override onEvent() HERE in this class, and make
        % it work the way we expect it
        onNiDaqReset(obj, niDaq)
    end
  
    methods
        function onNiDaqEvent(obj, event)
            % This function jumps like every onEvent() call, where the
            % event.creator == NiDaq and event.extraInfo doesn't have
            % the field EVENT_NIDAQ_RESET
        end
        function onEventNotNiDaq(obj, event)
            % this function jumps when receiving event with 
            % event.creator ~= NiDaq
        end
    end
    
    %% overridden from EventListener
    methods(Sealed = true)
        % this method is selaed. child classes can implement other methods
        % to achieve the same effect:
        %   @ onNiDaqReset - where sender is NiDaq and event is EVENT_NIDAQ_RESET
        %   @ onNiDaqEvent - where sender is NiDaq and event is anything but EVENT_NIDAQ_RESET
        %   @ onEventNotNiDaq - where sender is anything but the NiDaq
        % When events happen, this function jumps.
        % event is the event sent from the EventSender
        function onEvent(obj, event)
            if strcmp(event.creator.name, NiDaq.NAME)
                if isfield(event.extraInfo, NiDaq.EVENT_NIDAQ_RESET)
                    obj.onNiDaqReset(event.creator);
                else
                    obj.onNiDaqEvent(event);
                end
            else
                obj.onEventNotNiDaq(event);
            end
        end
    end
    
end

