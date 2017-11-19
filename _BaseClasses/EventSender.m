classdef EventSender < BaseObject
    %EVENTSENDER a member of this class can send events     
    %   those events can be captured by various listeners   
    %                                                       %
    %   child classes can use                               %
    %       @ sendEvent(struct)                             %
    %       @ sendWarning(msgString, optionalStruct)        %
    %       @ sendError(msgString, optionalStruct)          %
    %       @ sendErrorRealWorld()                          %
    %                                                       %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    methods(Access = protected)
        function obj = EventSender(name)
            % name - the object name
            obj@BaseObject(name);
        end
        
        function sendEvent(obj, optionalStructToSend)
            % sending an event to the station
            % optionalStructToSend - optional struct. empty struct will be
            %                        used if not supplied
            if exist('optionalStructToSend', 'var')
                eventToSend = Event(obj, optionalStructToSend);
            else
                eventToSend = Event(obj, struct);
            end
            station = EventStation.getInstance;
            station.newEvent(eventToSend);
        end
        
        function sendWarning(obj, errorString, extraInfoStructIfNeeded)
            % sending an error event to the controller
            % errorString - the error string to display
            % extraInfoStructIfNeeded - if you want to send the event with
            %       some extra info to be received by your listeners
            if exist('extraInfoIfNeeded', 'var')
                errorEvent = Event.createErrorEvent(obj, errorString, extraInfoStructIfNeeded);
            else
                errorEvent = Event.createErrorEvent(obj, errorString);
            end
            EventStation.getInstance.newEvent(errorEvent);
            warning(errorString);
        end
                
        function sendError(obj, errorString, extraInfoStructIfNeeded)
            % sending an error event to the controller
            % errorString - the error string to display
            % extraInfoStructIfNeeded - if you want to send the event with
            %       some extra info to be received by your listeners
            if exist('extraInfoIfNeeded', 'var')
                errorEvent = Event.createErrorEvent(obj, errorString, extraInfoStructIfNeeded);
            else
                errorEvent = Event.createErrorEvent(obj, errorString);
            end
            EventStation.getInstance.newEvent(errorEvent);
            error(errorString);
        end
        
        function sendErrorRealWorld(obj)
            obj.sendError('something in the real world just crashed. sorry');
        end
    end
end

