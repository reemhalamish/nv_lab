classdef SpcmCounter < Experiment
    %SPCMCOUNTER Read counts from SPCM via timer
    %   When switched on (reset), inits the vector of reads to be empty,
    %   and start a timer to read every 100ms.
    %   every time the timer clocks, a new read will be added to the
    %   vector.
    %
    %   The counter implements events from class Experiment, and adds event
    %   EVENT_SPCM_COUNTER_RESET, when we want to clear all results until
    %   now, and start anew.
    
    properties
        records     % vector, saves all previous scans since reset
        integrationTimeMillisec     % float, in milliseconds
    end
    
    properties (Constant, Hidden)
        EXP_NAME = 'SpcmCounter'
    end
    
    properties (Constant)
        EVENT_SPCM_COUNTER_RESET = 'SpcmCounterReset';
        EVENT_SPCM_COUNTER_STARTED = 'SpcmCounterStarted';
        EVENT_SPCM_COUNTER_UPDATED = 'SpcmCounterUpdated';
        EVENT_SPCM_COUNTER_STOPPED = 'SpcmCounterStopped';
        
        INTEGRATION_TIME_DEFAULT_MILLISEC = 100;
        DEFAULT_EMPTY_STRUCT = struct('time', 0, 'kcps', NaN, 'std', NaN);
    end
    
    methods
        function obj = SpcmCounter
            obj@Experiment();
            obj.integrationTimeMillisec = obj.INTEGRATION_TIME_DEFAULT_MILLISEC;
            obj.records = obj.DEFAULT_EMPTY_STRUCT;
            obj.isOn = false;
            
            obj.averages = 1;   % This Experiment has no averaging over repeats
        end
        
        function sendEventReset(obj)
            obj.sendEvent(struct(obj.EVENT_SPCM_COUNTER_RESET,true));
        end
        
        function reset(obj)
            obj.records = obj.DEFAULT_EMPTY_STRUCT;
            obj.sendEventReset;
        end
        
        function newRecord(obj, kcps, std)
            % creates new record in a struct of the type "record" =
            % record.{time,kcps,std}, with proper validation.
            integrationTime = obj.integrationTimeMillisec / 1000;
            time = obj.records(end).time + integrationTime;
            if kcps < 0 || std < 0 || kcps < std
                recordNum = length(obj.records);
                EventStation.anonymousWarning('Invalid values in time %d (record #%i)', time, recordNum)
            end
            obj.records(end + 1) = struct('time', time, 'kcps', kcps, 'std', std);
        end
        
        function [time, kcps, std] = getRecords(obj, lenOpt)
            lenRecords = length(obj.records);
            if ~exist('lenOpt', 'var')
                lenOpt = lenRecords;
            end
            
            difference = lenRecords - lenOpt;
            if difference < 0
                padding = abs(difference) - 1;
                maxTime = lenOpt*obj.integrationTimeMillisec/1000;  % Create time for end of wrap
                zeroStruct = struct('time', maxTime, 'kcps', 0, 'std', 0);
                data = [obj.records, ...
                    repelem(obj.DEFAULT_EMPTY_STRUCT,padding), ...
                    zeroStruct];
            elseif difference == 0
                data = obj.records;
            else
                position = difference + 1;
                data = obj.records(position:end);
            end
            
            time = [data.time];
            kcps = [data.kcps];
            std = [data.std];
        end
    end
    
    %% Overridden from Experiment
    methods
        function run(obj)
            obj.isOn = true;
            sendEventExpResumed(obj);
            
            integrationTime = obj.integrationTimeMillisec;  % For convenience
            
            spcm = getObjByName(Spcm.NAME);
            spcm.setSPCMEnable(true);
            spcm.prepareReadByTime(integrationTime/1000);
            
            try
                while obj.isOn
                    % Creating data to be saved
                    [kcps, std] = spcm.readFromTime;
                    obj.newRecord(kcps, std);
                    obj.sendEventDataUpdated;
                    if integrationTime ~= obj.integrationTimeMillisec
                        integrationTime = obj.integrationTimeMillisec;
                        spcm.clearTimeRead;
                        spcm.prepareReadByTime(integrationTime/1000);
                    end
                end
                spcm.clearTimeTask;
                
            catch err
                obj.pause;
                spcm.clearTimeTask;
                rethrow(err);
            end
        end
        
        function pause(obj)
            obj.isOn = false;
            pause((obj.integrationTimeMillisec + 1) / 1000);    % Let me finish what I was doing
            obj.sendEventExpPaused;
        end
    end
        
    methods
        % Functions that are abstract in superclass. Not relevant here.
        function prepare(obj) %#ok<MANU>
        end
        function perform(obj) %#ok<MANU> 
        end
        function analyze(obj) %#ok<MANU>
        end
    end
    
    %%
	methods (Static)
        function init
            try
                obj = getExpByName(SpcmCounter.EXP_NAME);
                obj.pause;
            catch
                % There was no such object, so we create one
                SpcmCounter;
            end
        end
    end

end