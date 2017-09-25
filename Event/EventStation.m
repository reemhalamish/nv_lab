classdef EventStation < handle
    %EVENTSTATION the station in which all the events go throuhgh 
    %   when an EventSender wants to send an event, it sends it to the
    %   station. than, the station iterates through all of the listeners
    %   and checks - if a listener listens to the event's name, it will
    %   receive a call to it's onEvent() method with the event as parameter
    
    properties
        eventListenersMap       % hashMap of {event-sender-name ---> event-listeners}
        listenersForAllEvents   % 1D cell-array of event listeners
        shouldShowEvents        % boolean. if is true, events will be shown in the command-line
    end
    
    methods(Static, Sealed)
        function obj = getInstance()
            persistent localObj
            if isempty(localObj) || ~isvalid(localObj)
                localObj = EventStation;
            end
            obj = localObj;
        end
        
        function anonymousError(errorMsg, varargin)
            % errorMsg - the error message to show
            % varargin - so we can pass multiple arguments (like sprintf)
            errorMsg = sprintf(errorMsg, varargin{:});
            EventStation.getInstance.newEvent(Event.createErrorEvent(struct('name', 'anonymous'), errorMsg));
            error(errorMsg); %#ok<SPERR>
        end
        
        function anonymousWarning(errorMsg, varargin)
            % errorMsg - the error message to show
            % varargin - so we can pass multiple arguments (like sprintf)
            errorMsg = sprintf(errorMsg, varargin{:});
            EventStation.getInstance.newEvent(Event.createErrorEvent(struct('name', 'anonymous'), errorMsg));
            warning(errorMsg); %#ok<SPWRN>
        end
    end
    
    methods(Access = private)
        function obj = EventStation()
            obj@handle;
            obj.eventListenersMap = containers.Map;
            obj.listenersForAllEvents = {};
            obj.shouldShowEvents = JsonInfoReader.getJson.showEvents;
        end
    end
    
    methods
        function registerListener(obj, eventListener, eventSenderName)
            % registers a new listener to the station
            %
            % eventListener - the listener to register
            % eventSenderName - string, the name to listen to
            if ~obj.eventListenersMap.isKey(eventSenderName)
                obj.eventListenersMap(eventSenderName) = {eventListener};
            else
                cells = obj.eventListenersMap(eventSenderName);
                if ~any(cellfun(@(x)  x == eventListener, cells)) 
                    % this if ^ is to make sure this listener isn't here
                    cells{end + 1} = eventListener;
                    obj.eventListenersMap(eventSenderName) = cells;
                end
            end
        end
        
        function registerListenerForAll(obj, eventListener)
            % registers a new listener to the station to listen for all the
            % events
            %
            % eventListener - the listener to register
            if ~any(cellfun(@(x)  x == eventListener, obj.listenersForAllEvents))
                % only add if it's not in already
                obj.listenersForAllEvents{end + 1} = eventListener;
            end
        end
        
        function removeListener(obj, listenerToRemove, eventSenderName)
            % removes a listener from listening for this eventSenderName
            %
            % listenerToRemove - the listener to remove
            % eventSenderName - string, the name that this listener was registered with
            if ~obj.eventListenersMap.isKey(eventSenderName)
                return
            end
            
            
            cells = obj.eventListenersMap(eventSenderName);
            allExceptToRemove = cellfun(@(x)  x ~= listenerToRemove, cells);
            newCells = cells(allExceptToRemove);
            if isempty(newCells)
                obj.eventListenersMap.remove(eventSenderName);
            else
                obj.eventListenersMap(eventSenderName) = newCells;
            end
            
            if obj.shouldShowEvents && length(newCells) ~= length(cells)
                obj.printRemove(listenerToRemove, eventSenderName)
            end
                
        end
        
        

        function removeListenerForAll(obj, listenerToRemove)
            % removes a listener from the station that listened for all the
            % events
            %
            % eventListener - the listener to remove
            cells = obj.listenersForAllEvents;
            allExceptToRemove = cellfun(@(x)  x ~= listenerToRemove, cells);
            newCells = cells(allExceptToRemove);
            if obj.shouldShowEvents && length(cells) ~= length(newCells)
                obj.printRemove(listenerToRemove, 'ALL EVENTS');
            end
            obj.listenersForAllEvents = newCells;
        end
        
        function printRemove(~, listenerToRemove, eventSenderName)
            fprintf( ...
                'deleting EventListener of type %s (listened to %s)\n', ...
                class(listenerToRemove), ...
                eventSenderName);
        end
        
        function out = newEvent(obj, event)
            if obj.shouldShowEvents
                disp(event);
                disp(event.extraInfo);
            end
            
            eventSender = event.creatorName;
            listenersForSender = {};
            if obj.eventListenersMap.isKey(eventSender) 
                listenersForSender = obj.eventListenersMap(eventSender);
            end
            for k = 1 : length(listenersForSender)
                listener = listenersForSender{k};
                    listener.onEvent(event);
            end
            
            for i = 1 : length(obj.listenersForAllEvents)
                listenerForAll = obj.listenersForAllEvents{i};
                if ~any(cellfun(@(x)  x == listenerForAll, listenersForSender))
                    % only call if this listener has not been invoked earlier
                    listenerForAll.onEvent(event);
                end
            end
            
            out = true;
        end
    end
end

