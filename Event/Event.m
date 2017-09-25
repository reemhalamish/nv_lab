classdef Event < handle
    %EVENT events are being sent from the physical parts to the gui parts (the listeners)
    
    properties
        creatorName     % is a string
        creator         % is an object
        extraInfo       % is a struct that the physics-object and the listener should know what inside
        isError         % boolean. is this en error event
    end
    
    properties(Constant = true, Hidden = true)
       ERROR_MSG = 'event_error_msg'; 
    end
    
    methods
        %% constructor for normal events
        function obj = Event(creator, extraInfoIfNeeded)
            % creator - object
            % extraInfoIfNeeded - a struct containing more information
            obj@handle();
            obj.creatorName = creator.name;
            obj.creator = creator;
            obj.isError = false;
            if exist('extraInfoIfNeeded', 'var')
                obj.extraInfo = extraInfoIfNeeded;
            else
                obj.extraInfo = struct();
            end
        end
    end
    methods(Static)
        %% constructor for error events
        function errorEvent = createErrorEvent(creator, errorMsgStr, extraInfoIfNeeded)
            % creator - the object that want to create an error event
            % errorMsgStr - the error message to be displayed            
            % extraInfoIfNeeded - optional struct
            
            if ~exist('extraInfoIfNeeded', 'var')
                extraInfoIfNeeded = struct(Event.ERROR_MSG, errorMsgStr);
            else
                extraInfoIfNeeded.(Event.ERROR_MSG) = errorMsgStr;
            end
                
           errorEvent = Event(creator, extraInfoIfNeeded);
           errorEvent.isError = true;
        end
    end
    
end

