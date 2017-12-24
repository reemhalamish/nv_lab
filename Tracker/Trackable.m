classdef (Abstract) Trackable < Experiment
    %TRACKABLE trackable experiment -- watches over drift of system
    % This experiment is invoked in constant intervals, to check if the
    % relevant parameters for the experiment have not changed
    
    properties (SetAccess = protected)
        mHistory = {};
        textOutput = [];
    end
    
    properties (Constant)
        EVENT_TRACKABLE_EXP_ENDED = 'TrackableExperimentFinished'
    end
    
    properties (Constant, Abstract)
        HISTORY_FIELDS
    end
    
    %%
    methods
        function sendEventTrackableExpEnded(obj)
            obj.sendEvent(struct(obj.EVENT_TRACKABLE_EXP_ENDED,true));
        end
        
        function clearHistory(obj)
            obj.mHistory = {};
        end
        
        function historyStruct = convertHistoryToStructToSave(obj)
            % Takes obj.mHistory and formats it as a struct which can be
            % sent to SaveLoad
            for fCell = obj.HISTORY_FIELDS
                field = char(fcell);    % MATLAB needs casting from cell to char array for the next line
                historyStruct.(field) = cellfun(@(c) c.(field), obj.mHistory);
            end
        end
        
    end
    
    methods (Abstract)
       params = getAllTrackalbeParameter(obj)
       % Returns a cell of values/paramters from the trackable experiment
       
       reset(obj)
       % Re-initialize the trackable
    end
    
    %% overridden from EventListener
    methods
        % When events happen, this function jumps.
        % event is the event sent from the EventSender
        function onEvent(obj, event) %#ok<INUSD>
        end
    end
    
end

