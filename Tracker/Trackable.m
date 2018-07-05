classdef (Abstract) Trackable < Experiment
    %TRACKABLE trackable experiment -- watches over drift of system
    % This experiment is invoked in constant intervals, to check if the
    % relevant parameters for the experiment have not changed
    
    properties (SetAccess = protected)
        mHistory = {};
        
        timer       % Stores tic from beginning of tracking
        stopFlag = false;
        isCurrentlyTracking = false;
    end
    
    properties
        isRunningContinuously
    end
    
    properties (Constant)
        PATH_ALL_TRACKABLES = sprintf('%sControl code\\%s\\Tracker\\Trackables\\', ...
            PathHelper.getPathToNvLab(), PathHelper.SetupMode);
        
        EVENT_TRACKABLE_EXP_ENDED = 'TrackableExperimentFinished'
        EVENT_TRACKABLE_EXP_UPDATED = 'TrackableExperimentUpdated'
        EVENT_CONTINUOUS_TRACKING_CHANGED = 'continuousTrackingChanged'
    end
    
    properties (Constant, Abstract)
        HISTORY_FIELDS
       
        DEFAULT_CONTINUOUS_TRACKING     % Should this tracker be on continuously by default? (probably false for all...)
    end
    
    %%
    methods
        function obj = Trackable
            obj@Experiment;
            obj.isRunningContinuously = obj.DEFAULT_CONTINUOUS_TRACKING;
        end
        
        function sendEventTrackableExpEnded(obj)
            s = struct;
            s.(obj.EVENT_TRACKABLE_EXP_ENDED) = true;
            s.text = obj.textOutput;
            obj.sendEvent(s);
        end
        
        function sendEventTrackableUpdated(obj)
            obj.sendEvent(struct(obj.EVENT_TRACKABLE_EXP_UPDATED,true));
        end
        
        
        function startTrack(obj)
            % (All functions are inherited from Experiment and implemented
            %  in subclasses)
            prepare(obj)
            
            obj.stopFlag = false;
            sendEventExpResumed(obj);
            perform(obj);
            
            stopTrack(obj)  % Signaling internally and externally that we are done
            analyze(obj)
            sendEventPlotAnalyzeFit(obj)
        end
        
        function stopTrack(obj)
            obj.stopFlag = true;
            obj.isCurrentlyTracking = false;
            obj.sendEventTrackableExpEnded;
        end
        
    end
        
    %% Helper functions
    methods
        function clearHistory(obj)
            obj.mHistory = {};
        end
        
        function historyStruct = convertHistoryToStructToSave(obj)
            % Takes obj.mHistory and formats it as a struct which can be
            % sent to SaveLoad
            for fCell = obj.HISTORY_FIELDS
                field = char(fCell);    % MATLAB needs casting from cell to char array for the next line
                historyStruct.(field) = cellfun(@(c) c.(field), obj.mHistory, 'UniformOutput', false);
                historyStruct.(field) = historyStruct.(field)';     % better formatting
            end
        end
        
        function t = myToc(obj)
            % By using this function we get time 0 for the beginning of
            % tracking (maybe usable by other experiments as well)
            if isempty(obj.timer)
                t = 0;
                obj.timer = tic;
            else
                t = toc(obj.timer);
            end
        end
    end
    
    methods %setters
        function set.isRunningContinuously(obj,newValue)
            obj.isRunningContinuously = newValue;
            obj.sendEvent(struct(obj.EVENT_CONTINUOUS_TRACKING_CHANGED,true));
        end
    end
    
    methods (Abstract)
       params = getAllTrackalbeParameter(obj)
       % Returns a cell of values/paramters from the trackable experiment
       
       resetTrack(obj)
       % Re-initialize the trackable
       
       str = textOutput(obj)
       % returns readable string with the results of the trackable
       % experiment
       
       %%%% Useful architecture, but private (so not obligatory)
       % recordCurrentState(obj)
       % Creates a record with the current state of the system (i.e. the
       % value of each of obj.HISTORY_FIELDS), and add it to obj.mHistory
    end
    
%     %% overridden from EventListener
%     methods
%         % When events happen, this function jumps.
%         % event is the event sent from the EventSender
%         function onEvent(obj, event) %#ok<INUSD>
%         end
%     end
    
end

